# frozen_string_literal: true

class RedirectLinkResolveWorker
  include Sidekiq::Worker
  include ExponentialBackoff
  include Redisable

  sidekiq_options queue: 'pull', retry: 3

  sidekiq_retries_exhausted do |msg|
    url, status_id = job['args']
    Sidekiq.logger.error("Processing redirect link resolver #{url} in #{status_id} failed with #{job['error_message']}")

    done_process(url, status_id)
  end

  def perform(url, status_id)
    parsed_url = Addressable::URI.parse(url)
    return if parsed_url.blank? || !%w(http https).include?(parsed_url.scheme) || parsed_url.host.blank? || RedirectLink.where(url: url).present?
    return if !FetchLinkCardService::IGNORE_REDIRECT_HOST.include?(parsed_url.host)

    Request.new(:get, url).add_headers('User-Agent' => Mastodon::Version.user_agent + ' Bot').perform do |res|
      if res.code == 200 && url != res.uri.to_s
        Request.new(:get, res.uri.to_s).add_headers('User-Agent' => Mastodon::Version.user_agent + ' Bot').perform do |res2|
          if res2.code == 200 && res.body == res2.body
            RedirectLink.create(url: url, redirected_url: res.uri.to_s)
          end
        end
      end
    end

    done_process(url, status_id)
  rescue HTTP::Error, OpenSSL::SSL::SSLError, Addressable::URI::InvalidURIError, Mastodon::HostValidationError
    done_process(url, status_id)
    true
  end

  private

  def done_process(url, status_id)
    redis.srem("statuses/#{status_id}/processing", "RedirectLinkResolveWorker:#{url}")
    redis.del("statuses/#{status_id}/processing") if redis.scard("statuses/#{status_id}/processing") <= 0
    StatusStat.find_by(status_id: status_id)&.touch || StatusStat.create!(status_id: status_id)
  end
end
