#!/usr/bin/env bash

brew install redis

brew services restart redis

rails new cable-ready-demo-code
cd cable-ready-demo-code
bundle remove tzinfo-data
bundle add cable_ready
yarn add cable_ready
bundle exec rails generate channel example

cat > app/assets/stylesheets/home.scss <<"DONE"
.big {
    font-size: 30px;
}

.colorful {
    color: orange;
}

DONE

cat > app/channels/example_channel.rb <<"DONE"
class ExampleChannel < ApplicationCable::Channel
  def subscribed
    stream_from "example-stream"
  end
end

DONE

cat > app/javascript/channels/example_channel.js <<"DONE"
import CableReady from 'cable_ready'
import consumer from './consumer'

consumer.subscriptions.create('ExampleChannel', {
  received (data) {
    if (data.cableReady) CableReady.perform(data.operations)
  }
})

DONE

mkdir -p app/views/home
cat > app/views/home/index.html.erb <<"DONE"
<h1>What will happen?</h1>

<div id="content">Waiting...</div>

DONE

cat > app/controllers/home_controller.rb <<"DONE"
class HomeController < ApplicationController
  def index
    ExampleJob.set(wait: 5.seconds).perform_later
  end
end

DONE

cat > config/routes.rb <<"DONE"
Rails.application.routes.draw do
  get 'home/index'
  root 'home#index'
end

DONE

cat > app/jobs/example_job.rb <<"DONE"
class ExampleJob < ApplicationJob
  include CableReady::Broadcaster
  queue_as :default

  def perform(*args)
    cable_ready["example-stream"].inner_html(
      selector: "#content",
      html: "<span>a big colorful hello!</span>"
    ).add_css_class(
      selector: "#content",
      name:     ["big", "colorful"]
    ).console_log(
      message: "no bugs so far"
    )
    cable_ready.broadcast
  end
end


DONE


rails server -p 4000
