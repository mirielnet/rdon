# frozen_string_literal: true

require_relative '../../config/boot'
require_relative '../../config/environment'
require_relative 'cli_helper'

module Mastodon
  class ConversationsCLI < Thor
    include CLIHelper
    include ActionView::Helpers::NumberHelper

    def self.exit_on_failure?
      true
    end

    desc 'remove', 'Remove unreferenced conversations'
    long_desc <<~LONG_DESC
      Remove unreferenced conversations, such as by tootctl statuses remove.
    LONG_DESC
    def remove
      start_at = Time.now.to_f

      say('Extract the deletion target... This might take a while...')

      ActiveRecord::Base.connection.create_table('conversations_to_be_deleted', temporary: true)

      ActiveRecord::Base.connection.exec_insert(<<-EOQ, 'SQL')
        INSERT INTO conversations_to_be_deleted (id)
        SELECT c.id FROM conversations c WHERE NOT EXISTS (SELECT 1 FROM statuses s WHERE s.conversation_id = c.id)
      EOQ

      say('Beginning removal... This might take a while...')

      klass = Class.new(ActiveRecord::Base) do |c|
        c.table_name = 'conversations_to_be_deleted'
      end

      Object.const_set('ConversationsToBeDeleted', klass)

      scope     = ConversationsToBeDeleted
      processed = 0
      removed   = 0
      progress  = create_progress_bar(scope.count.fdiv(1000).ceil)

      scope.reorder(nil).in_batches do |relation|
        ids        = relation.pluck(:id)
        processed += ids.count
        removed   += Conversation.unscoped.where(id: ids).delete_all
        progress.increment
      end

      progress.stop

      say("Done after #{Time.now.to_f - start_at}s, removed #{removed} out of #{processed} conversations.", :green)
    end
  end
end
