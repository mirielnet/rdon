# frozen_string_literal: true

# == Schema Information
#
# Table name: nodeinfos
#
#  id                     :bigint(8)        not null, primary key
#  domain                 :string           not null
#  nodeinfo               :jsonb
#  mastodon_instance      :jsonb
#  last_fetched_at        :datetime
#  status                 :integer          not null
#  override               :jsonb
#  note                   :string           not null
#  thumbnail_file_name    :string
#  thumbnail_content_type :string
#  thumbnail_file_size    :bigint(8)
#  thumbnail_updated_at   :datetime
#  blurhash               :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
class NodeInfo < ApplicationRecord
  ERROR_MISSING = { 'error': 'missing' }

  enum status: { up: 0, gone: 1, reject: 2, timeout: 3, error: 4 }, _suffix: :status

  def node?
    !missing?
  end

  def missing?
    nodeinfo&.dig('error') == 'missing'
  end

  def available?
    !gone_status? && DeliveryFailureTracker.available?(domain)
  end

  def possibly_stale?
    last_fetched_at.nil? || last_fetched_at <= 1.day.ago
  end

  def mastodon_api_compatible?
    %w(mastodon pleroma pixelfed).include?(compatible_software_name&.downcase)
  end

  COMPATIBLES = {
    'hometown' => 'mastodon',
    'fedibird' => 'mastodon',
    'akkoma'   => 'pleroma',
  }

  def software
    @software ||= begin
      software           = nodeinfo&.dig('software', 'name')&.downcase || ''
      version            = nodeinfo&.dig('software', 'version') || ''
      version1, version2 = version.split('+')
      version1           = version1&.strip || ''
      version2           = version2&.strip || ''

      if version2.blank?
        {
          compatible_software_name:    nodeinfo&.dig('metadata', 'upstream', 'name')&.downcase || COMPATIBLES[software] || software,
          compatible_software_version: nodeinfo&.dig('metadata', 'upstream', 'version') || version1,
          software_name:               software,
          software_version:            version1,
        }
      elsif /^[\d\.]$/i.match?(version2)
        {
          compatible_software_name:    COMPATIBLES[software] || software,
          compatible_software_version: version2,
          software_name:               software,
          software_version:            version1,
        }
      else
        {
          compatible_software_name:    COMPATIBLES[software] || software,
          compatible_software_version: version1,
          software_name:               software,
          software_version:            version,
        }
      end
    end
  end

  def software_name
    software[:software_name]
  end

  def software_version
    software[:software_version]
  end

  def compatible_software_name
    software[:compatible_software_name]
  end

  def compatible_software_version
    software[:compatible_software_version]
  end
end
