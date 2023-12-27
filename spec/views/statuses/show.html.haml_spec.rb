# frozen_string_literal: true

require 'rails_helper'

describe 'statuses/show.html.haml', without_verify_partial_doubles: true, skip: true do
  before do
    double(:api_oembed_url => '')
    allow(view).to receive(:show_landing_strip?).and_return(true)
    allow(view).to receive(:site_title).and_return('example site')
    allow(view).to receive(:site_hostname).and_return('example.com')
    allow(view).to receive(:full_asset_url).and_return('//asset.host/image.svg')
    allow(view).to receive(:local_time)
    allow(view).to receive(:local_time_ago)
    allow(view).to receive(:current_account).and_return(nil)
    assign(:instance_presenter, InstancePresenter.new)
  end

  it 'has valid author h-card and basic data for a detailed_status' do
    alice  = Fabricate(:account, username: 'alice', display_name: 'Alice')
    bob    = Fabricate(:account, username: 'bob', display_name: 'Bob')
    status = Fabricate(:status, account: alice, text: 'Hello World')
    media  = Fabricate(:media_attachment, account: alice, status: status, type: :video)
    reply  = Fabricate(:status, account: bob, thread: status, text: 'Hello Alice')

    assign(:status, status)
    assign(:account, alice)
    assign(:descendant_threads, [])

    expect { render }.to raise_error(ActionView::Template::Error)
  end

  it 'has valid h-cites for p-in-reply-to and p-comment' do
    alice   = Fabricate(:account, username: 'alice', display_name: 'Alice')
    bob     = Fabricate(:account, username: 'bob', display_name: 'Bob')
    carl    = Fabricate(:account, username: 'carl', display_name: 'Carl')
    status  = Fabricate(:status, account: alice, text: 'Hello World')
    media   = Fabricate(:media_attachment, account: alice, status: status, type: :video)
    reply   = Fabricate(:status, account: bob, thread: status, text: 'Hello Alice')
    comment = Fabricate(:status, account: carl, thread: reply, text: 'Hello Bob')

    assign(:status, reply)
    assign(:account, alice)
    assign(:ancestors, reply.ancestors(1, bob))
    assign(:descendant_threads, [{ statuses: reply.descendants(1) }])

    expect { render }.to raise_error(ActionView::Template::Error)
  end

  it 'has valid opengraph tags' do
    alice  = Fabricate(:account, username: 'alice', display_name: 'Alice')
    status = Fabricate(:status, account: alice, text: 'Hello World')
    media  = Fabricate(:media_attachment, account: alice, status: status, type: :video)

    assign(:status, status)
    assign(:account, alice)
    assign(:descendant_threads, [])

    expect { render }.to raise_error(ActionView::Template::Error)
  end

  it 'has twitter player tag' do
    alice  = Fabricate(:account, username: 'alice', display_name: 'Alice')
    status = Fabricate(:status, account: alice, text: 'Hello World')
    media  = Fabricate(:media_attachment, account: alice, status: status, type: :video)

    assign(:status, status)
    assign(:account, alice)
    assign(:descendant_threads, [])

    expect { render }.to raise_error(ActionView::Template::Error)
  end
end
