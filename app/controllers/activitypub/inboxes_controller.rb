# frozen_string_literal: true

class ActivityPub::InboxesController < ActivityPub::BaseController
  include SignatureVerification
  include JsonLdHelper
  include AccountOwnedConcern

  before_action :skip_unknown_actor_activity
  before_action :require_signature!
  skip_before_action :authenticate_user!

  def create
    upgrade_account
    process_collection_synchronization
    process_payload
    head 202
  end

  private

  def skip_unknown_actor_activity
    head 202 if unknown_affected_account?
  end

  def unknown_affected_account?
    json = Oj.load(body, mode: :strict)
    json.is_a?(Hash) && %w(Delete Update).include?(json['type']) && json['actor'].present? && json['actor'] == value_or_id(json['object']) && !Account.where(uri: json['actor']).exists?
  rescue Oj::ParseError
    false
  end

  def account_required?
    params[:account_username].present?
  end

  def skip_temporary_suspension_response?
    true
  end

  def body
    return @body if defined?(@body)

    @body = request.body.read
    @body.force_encoding('UTF-8') if @body.present?

    request.body.rewind if request.body.respond_to?(:rewind)

    @body
  end

  def upgrade_account
    if signed_request_account.ostatus?
      signed_request_account.update(last_webfingered_at: nil)
      ResolveAccountWorker.perform_async(signed_request_account.acct)
    end

    DeliveryFailureTracker.reset!(signed_request_account.inbox_url)
  end

  def process_collection_synchronization
    raw_params = request.headers['Collection-Synchronization']
    return if raw_params.blank? || ENV['DISABLE_FOLLOWERS_SYNCHRONIZATION'] == 'true'

    # Re-using the syntax for signature parameters
    tree   = SignatureParamsParser.new.parse(raw_params)
    params = SignatureParamsTransformer.new.apply(tree)

    ActivityPub::PrepareFollowersSynchronizationService.new.call(signed_request_account, params)
  rescue Parslet::ParseFailed
    Rails.logger.warn 'Error parsing Collection-Synchronization header'
  end

  def process_payload
    signed_request_account.high_priority? ? 
      ActivityPub::PriorityProcessingWorker.perform_async(signed_request_account.id, body, @account&.id) :
      ActivityPub::ProcessingWorker.perform_async(signed_request_account.id, body, @account&.id)
  end
end
