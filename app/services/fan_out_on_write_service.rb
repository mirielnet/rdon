# frozen_string_literal: true

class FanOutOnWriteService < BaseService
  include Redisable

  # Push a status into home and mentions feeds
  # @param [Status] status
  # @param [Hash] options
  # @option options [Boolean] update
  # @option options [Array<Integer>] silenced_account_ids
  def call(status, options = {})
    @status    = status
    @account   = status.account
    @options   = options

    check_race_condition!

    fan_out_to_local_recipients!
    fan_out_to_subscribe_recipients! if subscribable?
    fan_out_to_public_streams! if broadcastable?
  end

  private

  def check_race_condition!
    # I don't know why but at some point we had an issue where
    # this service was being executed with status objects
    # that had a null visibility - which should not be possible
    # since the column in the database is not nullable.
    #
    # This check re-queues the service to be run at a later time
    # with the full object, if something like it occurs

    raise Mastodon::RaceConditionError if @status.visibility.nil?
  end

  def fan_out_to_local_recipients!
    deliver_to_self!
    notify_mentioned_accounts!
    notify_about_update! if update?

    case @status.visibility.to_sym
    when :public, :unlisted, :private
      deliver_to_all_followers!
      deliver_to_lists!
    when :limited
      deliver_to_mentioned_followers!
    else
      deliver_to_mentioned_followers!
      deliver_to_conversation!
    end
  end

  def fan_out_to_subscribe_recipients!
    deliver_to_subscribers! if @status.public_visibility?
    deliver_to_domain_subscribers!

    return if @status.reblog?

    deliver_to_hashtag_followers!
    deliver_to_keyword_subscribers!
  end

  def fan_out_to_public_streams!
    broadcast_to_hashtag_streams!
    broadcast_to_public_streams!
  end

  def deliver_to_self!
    FeedManager.instance.push_to_home(@account, @status, update: update?) if @account.local?
  end

  def notify_mentioned_accounts!
    @status.active_mentions.where.not(id: @options[:silenced_account_ids] || []).joins(:account).merge(Account.local).select(:id, :account_id).reorder(nil).find_in_batches do |mentions|
      LocalNotificationWorker.push_bulk(mentions) do |mention|
        [mention.account_id, mention.id, 'Mention', 'mention']
      end
    end
  end

  def notify_about_update!
    @status.reblogged_by_accounts.merge(Account.local).select(:id).reorder(nil).find_in_batches do |accounts|
      LocalNotificationWorker.push_bulk(accounts) do |account|
        [account.id, @status.id, 'Status', 'update']
      end
    end
  end

  def deliver_to_all_followers!
    @account.followers_for_local_distribution.select(:id).reorder(nil).find_in_batches do |followers|
      FeedInsertWorker.push_bulk(followers) do |follower|
        [@status.id, follower.id, 'home', { 'update' => update? }]
      end
    end
  end

  def deliver_to_hashtag_followers!
    deliver_to_hashtag_followers_home!
    deliver_to_hashtag_followers_list!
  end

  def deliver_to_hashtag_followers_home!
    scope = FollowTag.home.where(tag_id: @status.tags.map(&:id))
    scope = scope.joins(:account).merge(@account.followers_for_local_distribution) if needs_following?

    scope.select(:id, :account_id).reorder(nil).find_in_batches do |follows|
      FeedInsertWorker.push_bulk(follows) do |follow|
        [@status.id, follow.account_id, 'subscribes', { 'update' => update? }]
      end
    end
  end

  def deliver_to_hashtag_followers_list!
    scope = FollowTag.list.where(tag_id: @status.tags.map(&:id))
    scope = scope.joins(:list).merge(List.joins(:account).merge(@account.followers_for_local_distribution)) if needs_following?

    scope.select(:id, :list_id).reorder(nil).find_in_batches do |follows|
      FeedInsertWorker.push_bulk(follows) do |follow|
        [@status.id, follow.list_id, 'subscribes_list', { 'update' => update? }]
      end
    end
  end

  def deliver_to_subscribers!
    deliver_to_subscribers_home!
    deliver_to_subscribers_lists!
  end

  def deliver_to_subscribers_home!
    @account.subscribers_for_local_distribution.with_reblog(@status.reblog?).select(:id, :account_id).reorder(nil).find_in_batches do |subscribings|
      FeedInsertWorker.push_bulk(subscribings) do |subscribing|
        [@status.id, subscribing.account_id, 'home', { 'update' => update? }]
      end
    end
  end

  def deliver_to_subscribers_lists!
    @account.list_subscribers_for_local_distribution.with_reblog(@status.reblog?).select(:id, :account_id).reorder(nil).find_in_batches do |subscribings|
      FeedInsertWorker.push_bulk(subscribings) do |subscribing|
        [@status.id, subscribing.list_id, 'list', { 'update' => update? }]
      end
    end
  end

  def deliver_to_domain_subscribers!
    deliver_to_domain_subscribers_home!
    deliver_to_domain_subscribers_list!
  end

  def deliver_to_domain_subscribers_home!
    scope = DomainSubscribe.domain_to_home(@account.domain).with_reblog(@status.reblog?)
    scope = scope.joins(:account).merge(@account.followers_for_local_distribution) if needs_following?

    scope.select(:id, :account_id).find_in_batches do |subscribes|
      FeedInsertWorker.push_bulk(subscribes) do |subscribe|
        [@status.id, subscribe.account_id, 'subscribes', { 'update' => update? }]
      end
    end
  end

  def deliver_to_domain_subscribers_list!
    scope = DomainSubscribe.domain_to_list(@account.domain).with_reblog(@status.reblog?)
    scope = scope.joins(:account).merge(@account.followers_for_local_distribution) if needs_following?

    scope.select(:id, :list_id).find_in_batches do |subscribes|
      FeedInsertWorker.push_bulk(subscribes) do |subscribe|
        [@status.id, subscribe.list_id, 'subscribes_list', { 'update' => update? }]
      end
    end
  end

  def deliver_to_keyword_subscribers!
    deliver_to_keyword_subscribers_home!
    deliver_to_keyword_subscribers_list!
  end

  def deliver_to_keyword_subscribers_home!
    match_accounts = []

    scope = KeywordSubscribe.active.without_local_followed_home(@account)
    scope = scope.joins(:account).merge(@account.followers_for_local_distribution) if needs_following?

    scope.order(:account_id).each do |keyword_subscribe|
      next if match_accounts[-1] == keyword_subscribe.account_id
      match_accounts << keyword_subscribe.account_id if keyword_subscribe.match?(@status.searchable_text)
    end

    FeedInsertWorker.push_bulk(match_accounts) do |match_account|
      [@status.id, match_account, 'subscribes', { 'update' => update? }]
    end
  end

  def deliver_to_keyword_subscribers_list!
    match_lists = []

    scope = KeywordSubscribe.active.without_local_followed_list(@account)
    scope = scope.joins(:account).merge(@account.followers_for_local_distribution) if needs_following?

    scope.order(:list_id).each do |keyword_subscribe|
      next if match_lists[-1] == keyword_subscribe.list_id
      match_lists << keyword_subscribe.list_id if keyword_subscribe.match?(@status.searchable_text)
    end

    FeedInsertWorker.push_bulk(match_lists) do |match_list|
      [@status.id, match_list, 'subscribes_list', { 'update' => update? }]
    end
  end

  def deliver_to_lists!
    @account.lists_for_local_distribution.select(:id).reorder(nil).find_in_batches do |lists|
      FeedInsertWorker.push_bulk(lists) do |list|
        [@status.id, list.id, 'list', { 'update' => update? }]
      end
    end
  end

  def deliver_to_mentioned_followers!
    @status.mentions.joins(:account).merge(@account.followers_for_local_distribution).select(:id, :account_id).reorder(nil).find_in_batches do |mentions|
      FeedInsertWorker.push_bulk(mentions) do |mention|
        [@status.id, mention.account_id, 'home', { 'update' => update? }]
      end
    end
  end

  def broadcast_to_hashtag_streams!
    @status.tags.map(&:name).each do |hashtag|
      redis.publish("timeline:hashtag:#{hashtag.mb_chars.downcase}", anonymous_payload)
      redis.publish("timeline:hashtag:#{hashtag.mb_chars.downcase}:local", anonymous_payload) if @status.local?
    end
  end

  def broadcast_to_public_streams!
    return if @status.reply? && @status.in_reply_to_account_id != @account.id

    redis.publish('timeline:public', anonymous_payload)
    redis.publish(@status.local? ? 'timeline:public:local' : 'timeline:public:remote', anonymous_payload)

    if @status.with_media?
      redis.publish('timeline:public:media', anonymous_payload)
      redis.publish(@status.local? ? 'timeline:public:local:media' : 'timeline:public:remote:media', anonymous_payload)
    end
  end

  def deliver_to_conversation!
    AccountConversation.add_status(@account, @status) unless update?
  end

  def anonymous_payload
    @anonymous_payload ||= Oj.dump(
      event: update? ? :'status.update' : :update,
      payload: InlineRenderer.render(@status, nil, :status)
    )
  end

  def update?
    @options[:update]
  end

  def subscribable?
    [:public, :unlisted, :private].include?(@status.visibility.to_sym)
  end

  def needs_following?
    [:unlisted, :private].include?(@status.visibility.to_sym) || @account.silenced?
  end

  def broadcastable?
    @status.public_visibility? && !@status.reblog? && !@account.silenced?
  end
end
