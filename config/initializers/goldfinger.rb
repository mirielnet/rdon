# frozen_string_literal: true

Goldfinger::Request.prepend Module.new {

  private

  def http_client
    HTTP.timeout(write: 10, connect: 5, read: 10).follow
  end
}
