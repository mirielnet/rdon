# frozen_string_literal: true

class UpdateNodeInfoService < BaseService
  include JsonLdHelper

  NODEINFO_2_1_REL = 'http://nodeinfo.diaspora.software/ns/schema/2.1'
  NODEINFO_2_0_REL = 'http://nodeinfo.diaspora.software/ns/schema/2.0'

  attr_reader :domain, :options, :nodeinfo
  
  def call(domain, **options)
    @domain   = domain
    @options  = options
    @nodeinfo = NodeInfo.find_or_create_by!(domain: domain)

    return unless options[:force] || nodeinfo.node? && nodeinfo.possibly_stale? && nodeinfo.available?

    fetch_nodeinfo
    fetch_mastodon_instance if nodeinfo.available? && nodeinfo.mastodon_api_compatible?
  end

  private

  def fetch_nodeinfo
    well_known_nodeinfo_url = "https://#{domain}/.well-known/nodeinfo"
    well_known_nodeinfo = json_fetch(well_known_nodeinfo_url)

    NodeInfo::ERROR_MISSING if well_known_nodeinfo.nil?

    nodeinfo_url   = well_known_nodeinfo['links'].find { |link| link&.fetch('rel', nil) == NODEINFO_2_1_REL }&.fetch('href', nil)
    nodeinfo_url ||= well_known_nodeinfo['links'].find { |link| link&.fetch('rel', nil) == NODEINFO_2_0_REL }&.fetch('href', nil)

    NodeInfo::ERROR_MISSING if nodeinfo_url.nil?

    json = json_fetch(nodeinfo_url, true)

    NodeInfo::ERROR_MISSING if json.nil?

    nodeinfo.update!(nodeinfo: json, status: :up, last_fetched_at: Time.now.utc)
  rescue Mastodon::UnexpectedResponseError => e
    if [404, 410].include?(e.code)
      nodeinfo.update!(status: :gone)
    elsif e.code == 501 || ((400...500).cover?(e.code) && ![401, 408, 429].include?(e.code))
      nodeinfo.update!(status: :error)
      raise
    else
      nodeinfo.update!(status: :reject)
      raise
    end
  rescue HTTP::TimeoutError, HTTP::ConnectionError, OpenSSL::SSL::SSLError
    nodeinfo.update!(status: :timeout)
    raise
  end

  def fetch_mastodon_instance
    instance_v2 = "https://#{domain}/api/v2/instance"
    instance_v1 = "https://#{domain}/api/v1/instance"

    major, minor, patch = nodeinfo.compatible_software_version&.split('.')&.map(&:to_i)

    json   = json_fetch(instance_v2) if major.nil? || major >= 4
    json ||= json_fetch(instance_v1)

    nodeinfo.update!(mastodon_instance: json) unless json.nil?
  end

  def json_fetch(url, raise_error = false)
    build_get_request(url).perform do |response|
      raise Mastodon::UnexpectedResponseError, response unless response_successful?(response) || !raise_error

      body_to_json(response.body_with_limit) if response.code == 200
    end
  end

  def build_get_request(url)
    Request.new(:get, url).tap do |request|
      request.add_headers('Accept' => 'application/json')
    end
  end
end
