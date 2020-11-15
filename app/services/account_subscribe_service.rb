# frozen_string_literal: true

class AccountSubscribeService < BaseService
  # Subscribe a remote user
  # @param [Account] source_account From which to subscribe
  # @param [String, Account] uri User URI to subscribe in the form of username@domain (or account record)
  def call(source_account, target_acct, **options)
    options = { show_reblogs: true, list_id: nil, media_only: false }.merge(options)

    target_account =
      if target_acct.instance_of?(Account)
        target_acct
      else
        begin
          ResolveAccountService.new.call(target_acct, skip_webfinger: true) || ResolveAccountService.new.call(target_acct, skip_webfinger: false)
        rescue
          nil
        end
      end

    raise ActiveRecord::RecordNotFound if target_account.nil? || target_account.id == source_account.id || target_account.suspended?
    raise Mastodon::NotPermittedError  if target_account.blocking?(source_account) || source_account.blocking?(target_account) || (!target_account.local? && target_account.ostatus?) || source_account.domain_blocking?(target_account.domain)

    already_subscribe = source_account.subscribing?(target_account, options[:list_id])

    source_account.subscribe!(target_account, **options).tap do
      if already_subscribe
        ActivityTracker.increment('activity:interactions')
        MergeWorker.perform_async(target_account.id, source_account.id, true)
      end
    end
  end
end
