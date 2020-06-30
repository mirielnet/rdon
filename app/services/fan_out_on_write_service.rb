# frozen_string_literal: true

class FanOutOnWriteService < BaseService
  # Push a status into home and mentions feeds
  # @param [Status] status
  def call(status)
    raise Mastodon::RaceConditionError if status.visibility.nil?

    render_anonymous_payload(status)

    if status.direct_visibility?
      deliver_to_own_conversation(status)
    end

    return if status.account.silenced? || !status.distributable?

    deliver_to_hashtags(status)
    deliver_to_public(status)
    deliver_to_media(status) if status.media_attachments.any?
  end

  private

  def render_anonymous_payload(status)
    @payload = InlineRenderer.render(status, nil, :status)
    @payload = Oj.dump(event: :update, payload: @payload)
  end

  def deliver_to_hashtags(status)
    Rails.logger.debug "Delivering status #{status.id} to hashtags"

    status.tags.pluck(:name).each do |hashtag|
      Redis.current.publish("timeline:hashtag:#{hashtag.mb_chars.downcase}", @payload)
      Redis.current.publish("timeline:hashtag:#{hashtag.mb_chars.downcase}:local", @payload) if status.local?
    end
  end

  def deliver_to_public(status)
    Rails.logger.debug "Delivering status #{status.id} to public timeline"

    if status.local?
      Redis.current.publish('timeline:public:local', @payload)
    end
  end

  def deliver_to_media(status)
    Rails.logger.debug "Delivering status #{status.id} to media timeline"

    if status.local?
      Redis.current.publish('timeline:public:local:media', @payload)
    end
  end

  def deliver_to_own_conversation(status)
    AccountConversation.add_status(status.account, status)
  end
end
