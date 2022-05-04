# Omniauth Marvin

[![Build Status](https://travis-ci.org/fakenine/omniauth-marvin.svg)](https://travis-ci.org/fakenine/omniauth-marvin) [![Maintainability](https://api.codeclimate.com/v1/badges/3c2ac09cff4d46183947/maintainability)](https://codeclimate.com/github/fakenine/omniauth-marvin/maintainability) [![Coverage Status](https://coveralls.io/repos/fakenine/omniauth-marvin/badge.svg?branch=master&service=github)](https://coveralls.io/github/fakenine/omniauth-marvin?branch=master)

OmniAuth OAuth2 strategy for 42 School.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'omniauth-marvin', '~> 1.2.0'
```

Or, install it yourself like below:

```
gem install omniauth-marvin
```

run `bundle install`

## Usage

**(Skip this if you want to use the gem with Devise to authenticate users)**

Register your application on 42's intranet to receive an API Key.

Here's an example for adding the middleware to a Rails app in `config/initializers/omniauth.rb`

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :marvin, ENV["FT_ID"], ENV["FT_SECRET"]
end
```

You can now access the OmniAuth 42 OAuth2 URL: `/auth/marvin`

Read the <a href="https://github.com/intridea/omniauth/wiki" target="_blank">Omniauth Wiki</a> or see this <a href="http://railscasts.com/episodes/241-simple-omniauth" target="_blank">RailsCast</a> for an example on how to use this Rack middleware without any other gem.

## Devise

If you wish to use this gem with devise, do **NOT** use the code snippet above in the Usage section. Instead, follow these steps:

Add the devise gem to your Gemfile.

```ruby
gem 'devise'
```

run `bundle install`

#### Generate migrations and models

```
rails g devise:install
rails g devise user
rails g devise:controllers users -c=omniauth_callbacks
rails g migration AddLoginToUsers login:string
rails g migration AddOmniauthToUsers provider:index uid:index
```

Before migrating, for this example since we are not going to use trackable, and all the devise module. Then please edit the file created into `db/*_devise_create_users`, to only keep:

```
# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.string :email,              null: false, default: ""
      t.timestamps null: false
    end
    add_index :users, :email,                unique: true
  end
end
```

now you can migrate:

```
rails db:migrate
```

You can add any additional migration you want. For instance, phone, level, wallet...etc.

#### Declare the provider

`config/initializers/devise.rb`

```ruby
Devise.setup do |config|
  .
  .
  config.omniauth :marvin, ENV["FT_ID"], ENV["FT_SECRET"]
  .
  .
end
```

Don't forget to set the "FT_ID" and "FT_SECRET" (your app id and secret) in your environment variables.

#### Make your model omniauthable

In this case, `app/models/user.rb`

```ruby
class User < ActiveRecord::Base
  devise :omniauthable, omniauth_providers: [:marvin]
end
```

#### Add the from_omniauth class method to the user model

`app/models/user.rb`

Example:

```ruby
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.login = auth.info.login
    end
  end
```

#### Implement a callback in the routes

`config/routes.rb`

```ruby
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }
```

#### Edit the callbacks controller

`app/controllers/users/omniauth_callbacks_controller.rb`

Example:

```ruby
# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def marvin
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: "42") if is_navigational_format?
    else
      session["devise.marvin_data"] = request.env["omniauth.auth"]
      redirect_to new_user_registration_url
    end
  end

  def after_omniauth_failure_path_for scope
    # instead of root_path you can add sign_in_path if you end up to have your own sign_in page.
    root_path
  end
end

```

#### Add the Sign Out route

`config/routes.rb`

```ruby
  devise_scope :user do
    delete 'sign_out', to: 'devise/sessions#destroy', as: :destroy_user_session
  end
```

#### Login/logout links

Here's a (very) basic example for login/logout links in the views

```erb
<%= link_to "Sign in with 42", user_marvin_omniauth_authorize_path unless current_user %>
<%= link_to "Sign out", destroy_user_session_path, method: :delete if current_user %>
```

**Warning: Rails >7**

You now need to pass the method through `data` like so:

```erb
<%= link_to "Sign out", destroy_user_session_path, data: { turbo_method: :delete } if current_user %>
```

#### More info

This section about devise and Omniauth was written with the help of devise documentation.
More info about devise and Omniauth on [their documentation](https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview "their documentation").

## Auth hash

Here's an example of the auth hash available in request.env['omniauth.auth']:

```json
{
  "provider": "marvin",
  "uid": 19265,
  "info": {
    "first_name": "Jordane",
    "last_name": "Gengo",
    "name": "Jordane Angelo Gengo",
    "email": "jgengo@student.42.fr",
    "login": "jgengo",
    "image": "https://cdn.intra.42.fr/users/jgengo.jpg",
    "urls": {
      "profile": "https://api.intra.42.fr/v2/users/jgengo"
    }
  },
  "credentials": {
    "token": "",
    "refresh_token": "",
    "expires_at": 1618602578,
    "expires": true
  },
  "extra": {
    "raw_info": {
      "id": 19265,
      "email": "jgengo@student.42.fr",
      "login": "jgengo",
      "first_name": "Jordane",
      "last_name": "Gengo",
      "usual_first_name": "Jordane angelo",
      "url": "https://api.intra.42.fr/v2/users/jgengo",
      "phone": "hidden",
      "displayname": "Jordane Gengo",
      "usual_full_name": "Jordane Angelo Gengo",
      "image_url": "https://cdn.intra.42.fr/users/jgengo.jpg",
      "staff?": false,
      "correction_point": 28,
      "pool_month": "july",
      "pool_year": "2016",
      "location": null,
      "wallet": 125,
      "anonymize_date": "2022-04-16T00:00:00.000+02:00",
      "groups": [],
      "cursus_users": [
        {
          "grade": "Admiral",
          "level": 21.0,
          "skills": [
            {
              "id": 16,
              "name": "Company experience",
              "level": 21.24
            },
            {
              "id": 7,
              "name": "Group \u0026 interpersonal",
              "level": 17.39
            },
            {
              "id": 6,
              "name": "Web",
              "level": 13.36
            },
            {
              "id": 10,
              "name": "Network \u0026 system administration",
              "level": 11.66
            },
            {
              "id": 14,
              "name": "Adaptation \u0026 creativity",
              "level": 11.54
            },
            {
              "id": 12,
              "name": "DB \u0026 Data",
              "level": 8.39
            },
            {
              "id": 1,
              "name": "Algorithms \u0026 AI",
              "level": 5.9
            },
            {
              "id": 2,
              "name": "Imperative programming",
              "level": 4.5600000000000005
            },
            {
              "id": 4,
              "name": "Unix",
              "level": 4.53
            },
            {
              "id": 11,
              "name": "Security",
              "level": 4.26
            },
            {
              "id": 3,
              "name": "Rigor",
              "level": 3.2
            },
            {
              "id": 15,
              "name": "Technology integration",
              "level": 2.73
            },
            {
              "id": 17,
              "name": "Object-oriented programming",
              "level": 1.71
            },
            {
              "id": 5,
              "name": "Graphics",
              "level": 1.28
            }
          ],
          "blackholed_at": null,
          "id": 16191,
          "begin_at": "2016-11-02T08:00:00.000Z",
          "end_at": "2019-12-01T00:00:00.000Z",
          "cursus_id": 1,
          "has_coalition": true,
          "user": {
            "id": 19265,
            "login": "jgengo",
            "url": "https://api.intra.42.fr/v2/users/jgengo"
          },
          "cursus": {
            "id": 1,
            "created_at": "2014-11-02T16:43:38.480Z",
            "name": "42",
            "slug": "42"
          }
        },
        {
          "grade": null,
          "level": 4.0,
          "skills": [
            {
              "id": 4,
              "name": "Unix",
              "level": 4.13
            },
            {
              "id": 3,
              "name": "Rigor",
              "level": 3.73
            },
            {
              "id": 1,
              "name": "Algorithms \u0026 AI",
              "level": 3.66
            },
            {
              "id": 7,
              "name": "Group \u0026 interpersonal",
              "level": 0.69
            }
          ],
          "blackholed_at": null,
          "id": 10033,
          "begin_at": "2016-06-30T21:42:00.000Z",
          "end_at": "2016-07-31T21:42:00.000Z",
          "cursus_id": 4,
          "has_coalition": true,
          "user": {
            "id": 19265,
            "login": "jgengo",
            "url": "https://api.intra.42.fr/v2/users/jgengo"
          },
          "cursus": {
            "id": 4,
            "created_at": "2015-05-01T17:46:08.433Z",
            "name": "Piscine C",
            "slug": "piscine-c"
          }
        },
        {
          "grade": "Member",
          "level": 21.01,
          "skills": [
            {
              "id": 16,
              "name": "Company experience",
              "level": 21.25
            },
            {
              "id": 7,
              "name": "Group \u0026 interpersonal",
              "level": 17.39
            },
            {
              "id": 6,
              "name": "Web",
              "level": 13.36
            },
            {
              "id": 10,
              "name": "Network \u0026 system administration",
              "level": 11.66
            },
            {
              "id": 14,
              "name": "Adaptation \u0026 creativity",
              "level": 11.54
            },
            {
              "id": 12,
              "name": "DB \u0026 Data",
              "level": 8.39
            },
            {
              "id": 1,
              "name": "Algorithms \u0026 AI",
              "level": 5.52
            },
            {
              "id": 2,
              "name": "Imperative programming",
              "level": 5.03
            },
            {
              "id": 4,
              "name": "Unix",
              "level": 5.02
            },
            {
              "id": 11,
              "name": "Security",
              "level": 4.87
            },
            {
              "id": 3,
              "name": "Rigor",
              "level": 4.29
            },
            {
              "id": 15,
              "name": "Technology integration",
              "level": 4.06
            },
            {
              "id": 17,
              "name": "Object-oriented programming",
              "level": 2.92
            },
            {
              "id": 5,
              "name": "Graphics",
              "level": 2.56
            }
          ],
          "blackholed_at": "2018-05-16T07:00:00.000Z",
          "id": 83052,
          "begin_at": "2016-11-02T08:00:00.000Z",
          "end_at": null,
          "cursus_id": 21,
          "has_coalition": true,
          "user": {
            "id": 19265,
            "login": "jgengo",
            "url": "https://api.intra.42.fr/v2/users/jgengo"
          },
          "cursus": {
            "id": 21,
            "created_at": "2019-07-29T08:45:17.896Z",
            "name": "42cursus",
            "slug": "42cursus"
          }
        }
      ],
      "projects_users": [
        {
          "id": 1024960,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 2173586,
          "project": {
            "id": 211,
            "name": "Peer Video",
            "slug": "final-internship-peer-video",
            "parent_id": 212
          },
          "cursus_ids": [1],
          "marked_at": "2018-08-28T13:21:42.412Z",
          "marked": true,
          "retriable_at": "2018-08-28T13:21:46.156Z"
        },
        {
          "id": 745865,
          "occurrence": 0,
          "final_mark": 125,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1844273,
          "project": {
            "id": 604,
            "name": "Darkly",
            "slug": "darkly",
            "parent_id": null
          },
          "cursus_ids": [1],
          "marked_at": "2017-11-28T18:03:50.501Z",
          "marked": true,
          "retriable_at": "2017-12-05T18:03:48.389Z"
        },
        {
          "id": 726705,
          "occurrence": 0,
          "final_mark": 125,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1838773,
          "project": {
            "id": 597,
            "name": "Hypertube",
            "slug": "hypertube",
            "parent_id": null
          },
          "cursus_ids": [1],
          "marked_at": "2017-11-11T13:00:09.534Z",
          "marked": true,
          "retriable_at": "2017-11-18T13:00:06.065Z"
        },
        {
          "id": 689963,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1780157,
          "project": {
            "id": 847,
            "name": "docker-1",
            "slug": "docker-1",
            "parent_id": null
          },
          "cursus_ids": [1],
          "marked_at": "2017-11-20T21:19:12.735Z",
          "marked": true,
          "retriable_at": "2017-11-23T21:19:10.824Z"
        },
        {
          "id": 689964,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1780158,
          "project": {
            "id": 687,
            "name": "init",
            "slug": "init",
            "parent_id": null
          },
          "cursus_ids": [1],
          "marked_at": "2017-11-23T10:48:16.000Z",
          "marked": true,
          "retriable_at": "2017-11-24T10:48:13.584Z"
        },
        {
          "id": 689434,
          "occurrence": 0,
          "final_mark": 125,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1779578,
          "project": {
            "id": 700,
            "name": "Dr Quine",
            "slug": "dr-quine",
            "parent_id": null
          },
          "cursus_ids": [1],
          "marked_at": "2017-09-25T09:06:43.558Z",
          "marked": true,
          "retriable_at": "2017-10-02T09:06:41.075Z"
        },
        {
          "id": 647141,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1728650,
          "project": {
            "id": 60,
            "name": "Rush01",
            "slug": "piscine-php-rush01",
            "parent_id": 48
          },
          "cursus_ids": [1],
          "marked_at": "2017-10-30T09:46:22.689Z",
          "marked": true,
          "retriable_at": "2017-10-30T09:46:22.674Z"
        },
        {
          "id": 647136,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1728642,
          "project": {
            "id": 54,
            "name": "Day 05",
            "slug": "42-piscine-c-formation-piscine-php-day-05",
            "parent_id": 48
          },
          "cursus_ids": [1],
          "marked_at": "2017-10-30T09:46:15.463Z",
          "marked": true,
          "retriable_at": "2017-10-21T13:56:59.293Z"
        },
        {
          "id": 647131,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1728648,
          "project": {
            "id": 50,
            "name": "Day 01",
            "slug": "42-piscine-c-formation-piscine-php-day-01",
            "parent_id": 48
          },
          "cursus_ids": [1],
          "marked_at": "2017-10-30T09:46:10.441Z",
          "marked": true,
          "retriable_at": "2017-10-30T09:46:10.413Z"
        },
        {
          "id": 647135,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1728649,
          "project": {
            "id": 59,
            "name": "Rush00",
            "slug": "piscine-php-rush00",
            "parent_id": 48
          },
          "cursus_ids": [1],
          "marked_at": "2017-10-30T09:46:15.392Z",
          "marked": true,
          "retriable_at": "2017-10-30T09:46:15.379Z"
        },
        {
          "id": 647139,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1728645,
          "project": {
            "id": 57,
            "name": "Day 08",
            "slug": "42-piscine-c-formation-piscine-php-day-08",
            "parent_id": 48
          },
          "cursus_ids": [1],
          "marked_at": "2017-10-30T09:46:20.024Z",
          "marked": true,
          "retriable_at": "2017-10-30T09:46:19.997Z"
        },
        {
          "id": 647137,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1728643,
          "project": {
            "id": 55,
            "name": "Day 06",
            "slug": "42-piscine-c-formation-piscine-php-day-06",
            "parent_id": 48
          },
          "cursus_ids": [1],
          "marked_at": "2017-10-30T09:46:16.640Z",
          "marked": true,
          "retriable_at": "2017-10-30T09:46:16.615Z"
        },
        {
          "id": 647130,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1728647,
          "project": {
            "id": 49,
            "name": "Day 00",
            "slug": "42-piscine-c-formation-piscine-php-day-00",
            "parent_id": 48
          },
          "cursus_ids": [1],
          "marked_at": "2017-10-30T09:56:23.449Z",
          "marked": true,
          "retriable_at": "2017-10-30T09:56:23.426Z"
        },
        {
          "id": 647140,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1728646,
          "project": {
            "id": 58,
            "name": "Day 09",
            "slug": "42-piscine-c-formation-piscine-php-day-09",
            "parent_id": 48
          },
          "cursus_ids": [1],
          "marked_at": "2017-10-30T09:46:21.440Z",
          "marked": true,
          "retriable_at": "2017-10-30T09:46:21.426Z"
        },
        {
          "id": 647138,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1728644,
          "project": {
            "id": 56,
            "name": "Day 07",
            "slug": "42-piscine-c-formation-piscine-php-day-07",
            "parent_id": 48
          },
          "cursus_ids": [1],
          "marked_at": "2017-10-30T09:46:18.297Z",
          "marked": true,
          "retriable_at": "2017-10-30T09:46:18.272Z"
        },
        {
          "id": 647132,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1728639,
          "project": {
            "id": 51,
            "name": "Day 02",
            "slug": "42-piscine-c-formation-piscine-php-day-02",
            "parent_id": 48
          },
          "cursus_ids": [1],
          "marked_at": "2017-10-30T09:46:11.788Z",
          "marked": true,
          "retriable_at": "2017-10-30T09:46:11.775Z"
        },
        {
          "id": 647133,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1728640,
          "project": {
            "id": 52,
            "name": "Day 03",
            "slug": "42-piscine-c-formation-piscine-php-day-03",
            "parent_id": 48
          },
          "cursus_ids": [1],
          "marked_at": "2017-10-30T09:46:12.574Z",
          "marked": true,
          "retriable_at": "2017-10-30T09:46:12.553Z"
        },
        {
          "id": 647134,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1728641,
          "project": {
            "id": 53,
            "name": "Day 04",
            "slug": "42-piscine-c-formation-piscine-php-day-04",
            "parent_id": 48
          },
          "cursus_ids": [1],
          "marked_at": "2017-10-30T09:46:13.729Z",
          "marked": true,
          "retriable_at": "2017-10-30T09:46:13.707Z"
        },
        {
          "id": 510252,
          "occurrence": 0,
          "final_mark": 118,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1647106,
          "project": {
            "id": 596,
            "name": "Matcha",
            "slug": "matcha",
            "parent_id": null
          },
          "cursus_ids": [1],
          "marked_at": "2017-10-21T13:54:23.662Z",
          "marked": true,
          "retriable_at": "2017-10-28T13:54:21.000Z"
        },
        {
          "id": 557311,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1619659,
          "project": {
            "id": 121,
            "name": "Peer Video",
            "slug": "first-internship-peer-video",
            "parent_id": 118
          },
          "cursus_ids": [1],
          "marked_at": "2018-01-10T11:55:46.173Z",
          "marked": true,
          "retriable_at": "2018-01-10T11:55:43.877Z"
        },
        {
          "id": 557310,
          "occurrence": 0,
          "final_mark": 111,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1619658,
          "project": {
            "id": 120,
            "name": "Company final evaluation",
            "slug": "first-internship-company-final-evaluation",
            "parent_id": 118
          },
          "cursus_ids": [1],
          "marked_at": "2018-04-17T08:39:55.911Z",
          "marked": true,
          "retriable_at": null
        },
        {
          "id": 557309,
          "occurrence": 0,
          "final_mark": 103,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1619657,
          "project": {
            "id": 826,
            "name": "Company mid evaluation",
            "slug": "first-internship-company-mid-evaluation",
            "parent_id": 118
          },
          "cursus_ids": [1],
          "marked_at": "2017-10-30T17:30:25.545Z",
          "marked": true,
          "retriable_at": null
        },
        {
          "id": 557308,
          "occurrence": 0,
          "final_mark": 125,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1619656,
          "project": {
            "id": 140,
            "name": "Duration",
            "slug": "first-internship-duration",
            "parent_id": 118
          },
          "cursus_ids": [1],
          "marked_at": "2017-07-13T15:24:05.314Z",
          "marked": true,
          "retriable_at": null
        },
        {
          "id": 557307,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1619655,
          "project": {
            "id": 119,
            "name": "Contract Upload",
            "slug": "first-internship-contract-upload",
            "parent_id": 118
          },
          "cursus_ids": [1],
          "marked_at": "2017-07-13T15:24:06.188Z",
          "marked": true,
          "retriable_at": "2017-07-13T15:22:35.355Z"
        },
        {
          "id": 490349,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1539043,
          "project": {
            "id": 537,
            "name": "Camagru",
            "slug": "camagru",
            "parent_id": null
          },
          "cursus_ids": [1],
          "marked_at": "2017-06-26T21:53:01.617Z",
          "marked": true,
          "retriable_at": "2017-06-30T21:53:01.595Z"
        },
        {
          "id": 445223,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": false,
          "current_team_id": 1483034,
          "project": {
            "id": 803,
            "name": "Rush01",
            "slug": "piscine-ruby-on-rails-rush01",
            "parent_id": 791
          },
          "cursus_ids": [1],
          "marked_at": "2018-04-24T12:17:53.476Z",
          "marked": true,
          "retriable_at": "2018-04-24T12:17:53.464Z"
        },
        {
          "id": 445417,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": false,
          "current_team_id": 1482625,
          "project": {
            "id": 802,
            "name": "Day 09",
            "slug": "piscine-ruby-on-rails-day-09",
            "parent_id": 791
          },
          "cursus_ids": [1],
          "marked_at": "2016-12-19T08:51:36.563Z",
          "marked": true,
          "retriable_at": "2016-12-19T08:51:36.542Z"
        },
        {
          "id": 445398,
          "occurrence": 0,
          "final_mark": 60,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1482605,
          "project": {
            "id": 801,
            "name": "Day 08",
            "slug": "piscine-ruby-on-rails-day-08",
            "parent_id": 791
          },
          "cursus_ids": [1],
          "marked_at": "2016-12-18T10:28:33.716Z",
          "marked": true,
          "retriable_at": null
        },
        {
          "id": 445249,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": false,
          "current_team_id": 1482406,
          "project": {
            "id": 800,
            "name": "Day 07",
            "slug": "piscine-ruby-on-rails-day-07",
            "parent_id": 791
          },
          "cursus_ids": [1],
          "marked_at": "2016-12-19T08:51:44.969Z",
          "marked": true,
          "retriable_at": null
        },
        {
          "id": 444700,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": false,
          "current_team_id": 1481444,
          "project": {
            "id": 799,
            "name": "Day 06",
            "slug": "piscine-ruby-on-rails-day-06",
            "parent_id": 791
          },
          "cursus_ids": [1],
          "marked_at": "2017-09-02T13:22:49.622Z",
          "marked": true,
          "retriable_at": null
        },
        {
          "id": 444265,
          "occurrence": 0,
          "final_mark": 67,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1481293,
          "project": {
            "id": 797,
            "name": "Rush00",
            "slug": "piscine-ruby-on-rails-rush00",
            "parent_id": 791
          },
          "cursus_ids": [1],
          "marked_at": "2016-12-12T11:14:22.358Z",
          "marked": true,
          "retriable_at": null
        },
        {
          "id": 444563,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": false,
          "current_team_id": 1481155,
          "project": {
            "id": 798,
            "name": "Day 05",
            "slug": "piscine-ruby-on-rails-day-05",
            "parent_id": 791
          },
          "cursus_ids": [1],
          "marked_at": "2017-01-23T15:45:59.963Z",
          "marked": true,
          "retriable_at": null
        },
        {
          "id": 444246,
          "occurrence": 0,
          "final_mark": 57,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1480669,
          "project": {
            "id": 795,
            "name": "Day 03",
            "slug": "piscine-ruby-on-rails-day-03",
            "parent_id": 791
          },
          "cursus_ids": [1],
          "marked_at": "2017-09-02T13:21:15.772Z",
          "marked": true,
          "retriable_at": "2016-12-10T08:32:11.097Z"
        },
        {
          "id": 444017,
          "occurrence": 0,
          "final_mark": 52,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1480110,
          "project": {
            "id": 796,
            "name": "Day 04",
            "slug": "piscine-ruby-on-rails-day-04",
            "parent_id": 791
          },
          "cursus_ids": [1],
          "marked_at": "2017-09-02T13:21:45.061Z",
          "marked": true,
          "retriable_at": null
        },
        {
          "id": 443840,
          "occurrence": 0,
          "final_mark": 79,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1479803,
          "project": {
            "id": 793,
            "name": "Day 01",
            "slug": "piscine-ruby-on-rails-day-01",
            "parent_id": 791
          },
          "cursus_ids": [1],
          "marked_at": "2017-04-14T12:09:05.529Z",
          "marked": true,
          "retriable_at": "2016-12-08T09:31:57.882Z"
        },
        {
          "id": 443734,
          "occurrence": 0,
          "final_mark": 54,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1479633,
          "project": {
            "id": 794,
            "name": "Day 02",
            "slug": "piscine-ruby-on-rails-day-02",
            "parent_id": 791
          },
          "cursus_ids": [1],
          "marked_at": "2017-09-02T13:20:48.671Z",
          "marked": true,
          "retriable_at": "2016-12-09T08:31:34.860Z"
        },
        {
          "id": 443507,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1479238,
          "project": {
            "id": 792,
            "name": "Day 00",
            "slug": "piscine-ruby-on-rails-day-00",
            "parent_id": 791
          },
          "cursus_ids": [1],
          "marked_at": "2017-09-02T13:20:20.725Z",
          "marked": true,
          "retriable_at": "2016-12-07T11:54:49.168Z"
        },
        {
          "id": 441655,
          "occurrence": 0,
          "final_mark": 125,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1476768,
          "project": {
            "id": 4,
            "name": "FdF",
            "slug": "fdf",
            "parent_id": null
          },
          "cursus_ids": [1],
          "marked_at": "2017-01-19T13:14:05.528Z",
          "marked": true,
          "retriable_at": "2017-01-23T13:14:03.928Z"
        },
        {
          "id": 441081,
          "occurrence": 0,
          "final_mark": 120,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1475754,
          "project": {
            "id": 2,
            "name": "GET_Next_Line",
            "slug": "get_next_line",
            "parent_id": null
          },
          "cursus_ids": [1],
          "marked_at": "2016-11-23T13:53:08.519Z",
          "marked": true,
          "retriable_at": "2016-11-24T13:53:08.498Z"
        },
        {
          "id": 438787,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1472240,
          "project": {
            "id": 540,
            "name": "Fillit",
            "slug": "fillit",
            "parent_id": null
          },
          "cursus_ids": [1],
          "marked_at": "2016-11-21T10:15:08.258Z",
          "marked": true,
          "retriable_at": "2016-11-23T10:15:08.142Z"
        },
        {
          "id": 433800,
          "occurrence": 0,
          "final_mark": 125,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1465152,
          "project": {
            "id": 1,
            "name": "Libft",
            "slug": "libft",
            "parent_id": null
          },
          "cursus_ids": [1],
          "marked_at": "2017-11-11T12:20:50.167Z",
          "marked": true,
          "retriable_at": "2017-11-12T12:20:50.145Z"
        },
        {
          "id": 428286,
          "occurrence": 7,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1465141,
          "project": {
            "id": 756,
            "name": "Piscine Reloaded",
            "slug": "piscine-reloaded",
            "parent_id": null
          },
          "cursus_ids": [1],
          "marked_at": "2016-11-04T11:05:10.867Z",
          "marked": true,
          "retriable_at": "2016-11-04T11:05:10.842Z"
        },
        {
          "id": 428058,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1458252,
          "project": {
            "id": 817,
            "name": "42 Commandements",
            "slug": "42-formation-pole-emploi-42-commandements",
            "parent_id": null
          },
          "cursus_ids": [1],
          "marked_at": "2016-11-02T09:34:42.896Z",
          "marked": true,
          "retriable_at": "2016-11-02T09:34:42.868Z"
        },
        {
          "id": 305685,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1331518,
          "project": {
            "id": 170,
            "name": "Rush 02",
            "slug": "piscine-c-rush-02",
            "parent_id": null
          },
          "cursus_ids": [4],
          "marked_at": "2016-08-08T22:12:05.820Z",
          "marked": true,
          "retriable_at": "2016-07-28T13:03:50.789Z"
        },
        {
          "id": 305684,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": false,
          "current_team_id": 1327458,
          "project": {
            "id": 173,
            "name": "EvalExpr",
            "slug": "piscine-c-evalexpr",
            "parent_id": null
          },
          "cursus_ids": [4],
          "marked_at": "2016-07-25T21:51:31.751Z",
          "marked": true,
          "retriable_at": "2016-07-25T21:51:31.721Z"
        },
        {
          "id": 302832,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": false,
          "current_team_id": 1325029,
          "project": {
            "id": 174,
            "name": "BSQ",
            "slug": "bsq",
            "parent_id": null
          },
          "cursus_ids": [4],
          "marked_at": "2017-08-26T08:52:14.651Z",
          "marked": true,
          "retriable_at": "2016-07-28T11:30:57.306Z"
        },
        {
          "id": 302233,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": false,
          "current_team_id": 1324427,
          "project": {
            "id": 166,
            "name": "Day 13",
            "slug": "piscine-c-day-13",
            "parent_id": null
          },
          "cursus_ids": [4],
          "marked_at": "2016-07-23T22:08:20.470Z",
          "marked": true,
          "retriable_at": "2016-07-23T22:08:20.448Z"
        },
        {
          "id": 301506,
          "occurrence": 0,
          "final_mark": 25,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1323691,
          "project": {
            "id": 165,
            "name": "Day 12",
            "slug": "piscine-c-day-12",
            "parent_id": null
          },
          "cursus_ids": [4],
          "marked_at": "2016-07-23T17:53:08.135Z",
          "marked": true,
          "retriable_at": "2016-07-22T12:13:34.491Z"
        },
        {
          "id": 300265,
          "occurrence": 0,
          "final_mark": 5,
          "status": "finished",
          "validated?": false,
          "current_team_id": 1322428,
          "project": {
            "id": 164,
            "name": "Day 11",
            "slug": "piscine-c-day-11",
            "parent_id": null
          },
          "cursus_ids": [4],
          "marked_at": "2016-07-23T18:02:57.536Z",
          "marked": true,
          "retriable_at": "2016-07-21T09:06:03.906Z"
        },
        {
          "id": 300264,
          "occurrence": 0,
          "final_mark": 25,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1322427,
          "project": {
            "id": 163,
            "name": "Day 10",
            "slug": "piscine-c-day-10",
            "parent_id": null
          },
          "cursus_ids": [4],
          "marked_at": "2017-07-19T12:14:42.803Z",
          "marked": true,
          "retriable_at": "2016-07-20T07:33:55.004Z"
        },
        {
          "id": 280586,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": false,
          "current_team_id": 1321552,
          "project": {
            "id": 169,
            "name": "Rush 01",
            "slug": "piscine-c-rush-01",
            "parent_id": null
          },
          "cursus_ids": [4],
          "marked_at": "2016-08-08T22:11:01.108Z",
          "marked": true,
          "retriable_at": "2016-07-19T11:28:14.003Z"
        },
        {
          "id": 280348,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": false,
          "current_team_id": 1302466,
          "project": {
            "id": 172,
            "name": "Match-N-Match",
            "slug": "piscine-c-match-n-match",
            "parent_id": null
          },
          "cursus_ids": [4],
          "marked_at": "2017-08-14T07:41:32.464Z",
          "marked": true,
          "retriable_at": "2016-07-20T16:21:09.214Z"
        },
        {
          "id": 270808,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": false,
          "current_team_id": 1292967,
          "project": {
            "id": 162,
            "name": "Day 08",
            "slug": "piscine-c-day-08",
            "parent_id": null
          },
          "cursus_ids": [4],
          "marked_at": "2016-07-17T08:58:20.205Z",
          "marked": true,
          "retriable_at": "2016-07-17T08:58:20.183Z"
        },
        {
          "id": 269669,
          "occurrence": 0,
          "final_mark": 16,
          "status": "finished",
          "validated?": false,
          "current_team_id": 1291599,
          "project": {
            "id": 161,
            "name": "Day 07",
            "slug": "piscine-c-day-07",
            "parent_id": null
          },
          "cursus_ids": [4],
          "marked_at": "2016-07-15T21:45:38.366Z",
          "marked": true,
          "retriable_at": "2016-07-15T21:45:38.355Z"
        },
        {
          "id": 269341,
          "occurrence": 0,
          "final_mark": 70,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1291266,
          "project": {
            "id": 160,
            "name": "Day 06",
            "slug": "piscine-c-day-06",
            "parent_id": null
          },
          "cursus_ids": [4],
          "marked_at": "2016-07-14T10:30:47.314Z",
          "marked": true,
          "retriable_at": "2016-07-14T10:30:47.290Z"
        },
        {
          "id": 267718,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1290709,
          "project": {
            "id": 168,
            "name": "Rush 00",
            "slug": "piscine-c-rush-00",
            "parent_id": null
          },
          "cursus_ids": [4],
          "marked_at": "2017-09-16T11:52:20.454Z",
          "marked": true,
          "retriable_at": "2016-07-13T14:39:17.628Z"
        },
        {
          "id": 268069,
          "occurrence": 0,
          "final_mark": 20,
          "status": "finished",
          "validated?": false,
          "current_team_id": 1289816,
          "project": {
            "id": 159,
            "name": "Day 05",
            "slug": "piscine-c-day-05",
            "parent_id": null
          },
          "cursus_ids": [4],
          "marked_at": "2016-07-23T03:10:40.577Z",
          "marked": true,
          "retriable_at": "2016-07-13T12:15:30.702Z"
        },
        {
          "id": 267717,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": false,
          "current_team_id": 1289561,
          "project": {
            "id": 171,
            "name": "Sastantua",
            "slug": "piscine-c-sastantua",
            "parent_id": null
          },
          "cursus_ids": [4],
          "marked_at": "2017-09-08T14:55:07.132Z",
          "marked": true,
          "retriable_at": "2016-07-15T20:15:17.665Z"
        },
        {
          "id": 264171,
          "occurrence": 0,
          "final_mark": 20,
          "status": "finished",
          "validated?": false,
          "current_team_id": 1286582,
          "project": {
            "id": 158,
            "name": "Day 04",
            "slug": "piscine-c-day-04",
            "parent_id": null
          },
          "cursus_ids": [4],
          "marked_at": "2016-08-06T10:07:36.923Z",
          "marked": true,
          "retriable_at": "2016-07-10T16:20:58.775Z"
        },
        {
          "id": 262516,
          "occurrence": 0,
          "final_mark": 65,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1284884,
          "project": {
            "id": 157,
            "name": "Day 03",
            "slug": "piscine-c-day-03",
            "parent_id": null
          },
          "cursus_ids": [4],
          "marked_at": "2017-09-08T17:01:47.326Z",
          "marked": true,
          "retriable_at": "2016-07-10T16:01:36.514Z"
        },
        {
          "id": 262515,
          "occurrence": 0,
          "final_mark": 43,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1284883,
          "project": {
            "id": 156,
            "name": "Day 02",
            "slug": "piscine-c-day-02",
            "parent_id": null
          },
          "cursus_ids": [4],
          "marked_at": "2016-07-23T02:18:25.281Z",
          "marked": true,
          "retriable_at": "2016-07-08T12:05:48.874Z"
        },
        {
          "id": 262513,
          "occurrence": 0,
          "final_mark": 85,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1284881,
          "project": {
            "id": 155,
            "name": "Day 01",
            "slug": "piscine-c-day-01",
            "parent_id": null
          },
          "cursus_ids": [4],
          "marked_at": "2016-07-23T02:01:40.041Z",
          "marked": true,
          "retriable_at": "2016-07-07T15:16:58.180Z"
        },
        {
          "id": 260667,
          "occurrence": 0,
          "final_mark": 50,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1283022,
          "project": {
            "id": 154,
            "name": "Day 00",
            "slug": "piscine-c-day-00",
            "parent_id": null
          },
          "cursus_ids": [4],
          "marked_at": "2016-07-23T01:43:53.891Z",
          "marked": true,
          "retriable_at": "2016-07-06T15:43:45.128Z"
        },
        {
          "id": 285242,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1307201,
          "project": {
            "id": 203,
            "name": "19",
            "slug": "piscine-c-day-09-19",
            "parent_id": 167
          },
          "cursus_ids": [4],
          "marked_at": "2017-09-01T17:52:54.763Z",
          "marked": true,
          "retriable_at": "2017-09-01T17:52:54.731Z"
        },
        {
          "id": 285237,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1307196,
          "project": {
            "id": 202,
            "name": "18",
            "slug": "piscine-c-day-09-18",
            "parent_id": 167
          },
          "cursus_ids": [4],
          "marked_at": "2017-09-01T17:52:56.112Z",
          "marked": true,
          "retriable_at": "2017-09-01T17:52:56.082Z"
        },
        {
          "id": 303695,
          "occurrence": 0,
          "final_mark": 94,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1325689,
          "project": {
            "id": 406,
            "name": "Exam02",
            "slug": "piscine-c-exam02",
            "parent_id": null
          },
          "cursus_ids": [4],
          "marked_at": "2016-07-19T17:56:18.000Z",
          "marked": true,
          "retriable_at": "2017-06-26T21:47:08.881Z"
        },
        {
          "id": 311027,
          "occurrence": 0,
          "final_mark": 75,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1332698,
          "project": {
            "id": 407,
            "name": "Exam Final",
            "slug": "piscine-c-exam-final",
            "parent_id": null
          },
          "cursus_ids": [4],
          "marked_at": "2016-07-26T08:05:04.000Z",
          "marked": true,
          "retriable_at": "2017-06-26T21:48:14.023Z"
        },
        {
          "id": 440462,
          "occurrence": 5,
          "final_mark": 79,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1483734,
          "project": {
            "id": 11,
            "name": "C Exam Alone In The Dark - Beginner",
            "slug": "c-exam-alone-in-the-dark-beginner",
            "parent_id": null
          },
          "cursus_ids": [1],
          "marked_at": "2016-12-27T10:16:57.072Z",
          "marked": true,
          "retriable_at": "2016-12-27T10:16:31.371Z"
        },
        {
          "id": 443482,
          "occurrence": 0,
          "final_mark": 69,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1479204,
          "project": {
            "id": 791,
            "name": "Piscine Ruby on Rails",
            "slug": "piscine-ruby-on-rails",
            "parent_id": null
          },
          "cursus_ids": [1],
          "marked_at": "2018-04-24T12:17:53.367Z",
          "marked": true,
          "retriable_at": "2018-04-24T12:17:53.320Z"
        },
        {
          "id": 647129,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1728636,
          "project": {
            "id": 48,
            "name": "Piscine PHP",
            "slug": "piscine-php",
            "parent_id": null
          },
          "cursus_ids": [1],
          "marked_at": "2017-10-30T09:57:31.242Z",
          "marked": true,
          "retriable_at": "2017-10-30T09:57:31.209Z"
        },
        {
          "id": 534508,
          "occurrence": 0,
          "final_mark": 123,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1593193,
          "project": {
            "id": 118,
            "name": "First Internship",
            "slug": "first-internship",
            "parent_id": null
          },
          "cursus_ids": [1],
          "marked_at": "2018-04-17T08:39:55.877Z",
          "marked": true,
          "retriable_at": "2018-04-17T08:39:55.837Z"
        },
        {
          "id": 825428,
          "occurrence": 0,
          "final_mark": 125,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1940692,
          "project": {
            "id": 209,
            "name": "Duration",
            "slug": "final-internship-duration",
            "parent_id": 212
          },
          "cursus_ids": [1],
          "marked_at": "2018-03-23T14:10:08.490Z",
          "marked": true,
          "retriable_at": null
        },
        {
          "id": 825427,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1940691,
          "project": {
            "id": 208,
            "name": "Contract Upload",
            "slug": "final-internship-contract-upload",
            "parent_id": 212
          },
          "cursus_ids": [1],
          "marked_at": "2018-03-23T14:10:08.050Z",
          "marked": true,
          "retriable_at": "2018-03-23T14:10:08.026Z"
        },
        {
          "id": 825429,
          "occurrence": 0,
          "final_mark": 118,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1940693,
          "project": {
            "id": 827,
            "name": "Company mid evaluation",
            "slug": "final-internship-company-mid-evaluation",
            "parent_id": 212
          },
          "cursus_ids": [1],
          "marked_at": "2018-05-28T11:53:57.910Z",
          "marked": true,
          "retriable_at": null
        },
        {
          "id": 791493,
          "occurrence": 0,
          "final_mark": 125,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1899477,
          "project": {
            "id": 212,
            "name": "Final Internship",
            "slug": "final-internship",
            "parent_id": null
          },
          "cursus_ids": [1],
          "marked_at": "2018-08-28T13:21:43.234Z",
          "marked": true,
          "retriable_at": "2018-08-28T13:21:46.074Z"
        },
        {
          "id": 825430,
          "occurrence": 0,
          "final_mark": 118,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1940694,
          "project": {
            "id": 210,
            "name": "Company final evaluation",
            "slug": "final-internship-company-final-evaluation",
            "parent_id": 212
          },
          "cursus_ids": [1],
          "marked_at": "2018-08-24T11:33:09.862Z",
          "marked": true,
          "retriable_at": null
        },
        {
          "id": 265317,
          "occurrence": 0,
          "final_mark": 65,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1287775,
          "project": {
            "id": 404,
            "name": "Exam00",
            "slug": "piscine-c-exam00",
            "parent_id": null
          },
          "cursus_ids": [4],
          "marked_at": "2016-07-08T16:49:32.159Z",
          "marked": true,
          "retriable_at": "2016-07-08T16:45:08.743Z"
        },
        {
          "id": 274412,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1296663,
          "project": {
            "id": 192,
            "name": "08",
            "slug": "piscine-c-day-09-08",
            "parent_id": 167
          },
          "cursus_ids": [4],
          "marked_at": "2017-09-01T17:52:58.680Z",
          "marked": true,
          "retriable_at": "2017-09-01T17:52:58.641Z"
        },
        {
          "id": 274454,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1296705,
          "project": {
            "id": 197,
            "name": "13",
            "slug": "piscine-c-day-09-13",
            "parent_id": 167
          },
          "cursus_ids": [4],
          "marked_at": "2017-09-01T17:52:57.205Z",
          "marked": true,
          "retriable_at": "2017-09-01T17:52:57.165Z"
        },
        {
          "id": 274444,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1296695,
          "project": {
            "id": 195,
            "name": "11",
            "slug": "piscine-c-day-09-11",
            "parent_id": 167
          },
          "cursus_ids": [4],
          "marked_at": "2017-09-01T17:52:57.881Z",
          "marked": true,
          "retriable_at": "2017-09-01T17:52:57.850Z"
        },
        {
          "id": 274392,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1296643,
          "project": {
            "id": 186,
            "name": "02",
            "slug": "piscine-c-day-09-02",
            "parent_id": 167
          },
          "cursus_ids": [4],
          "marked_at": "2017-09-01T17:53:00.383Z",
          "marked": true,
          "retriable_at": "2017-09-01T17:53:00.352Z"
        },
        {
          "id": 274413,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1296664,
          "project": {
            "id": 193,
            "name": "09",
            "slug": "piscine-c-day-09-09",
            "parent_id": 167
          },
          "cursus_ids": [4],
          "marked_at": "2017-09-01T17:52:58.485Z",
          "marked": true,
          "retriable_at": "2017-09-01T17:52:58.440Z"
        },
        {
          "id": 274386,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1296637,
          "project": {
            "id": 175,
            "name": "00",
            "slug": "piscine-c-day-09-00",
            "parent_id": 167
          },
          "cursus_ids": [4],
          "marked_at": "2017-09-01T17:53:00.782Z",
          "marked": true,
          "retriable_at": "2017-09-01T17:53:00.761Z"
        },
        {
          "id": 274462,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1296713,
          "project": {
            "id": 198,
            "name": "14",
            "slug": "piscine-c-day-09-14",
            "parent_id": 167
          },
          "cursus_ids": [4],
          "marked_at": "2017-09-01T17:52:56.948Z",
          "marked": true,
          "retriable_at": "2017-09-01T17:52:56.905Z"
        },
        {
          "id": 274389,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1296640,
          "project": {
            "id": 185,
            "name": "01",
            "slug": "piscine-c-day-09-01",
            "parent_id": 167
          },
          "cursus_ids": [4],
          "marked_at": "2017-09-01T17:53:00.588Z",
          "marked": true,
          "retriable_at": "2017-09-01T17:53:00.552Z"
        },
        {
          "id": 274394,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1296645,
          "project": {
            "id": 187,
            "name": "03",
            "slug": "piscine-c-day-09-03",
            "parent_id": 167
          },
          "cursus_ids": [4],
          "marked_at": "2017-09-01T17:53:00.167Z",
          "marked": true,
          "retriable_at": "2017-09-01T17:53:00.126Z"
        },
        {
          "id": 274450,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1296701,
          "project": {
            "id": 196,
            "name": "12",
            "slug": "piscine-c-day-09-12",
            "parent_id": 167
          },
          "cursus_ids": [4],
          "marked_at": "2017-09-01T17:52:57.553Z",
          "marked": true,
          "retriable_at": "2017-09-01T17:52:57.514Z"
        },
        {
          "id": 274467,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1296718,
          "project": {
            "id": 199,
            "name": "15",
            "slug": "piscine-c-day-09-15",
            "parent_id": 167
          },
          "cursus_ids": [4],
          "marked_at": "2017-09-01T17:52:56.634Z",
          "marked": true,
          "retriable_at": "2017-09-01T17:52:56.585Z"
        },
        {
          "id": 274400,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1296651,
          "project": {
            "id": 189,
            "name": "05",
            "slug": "piscine-c-day-09-05",
            "parent_id": 167
          },
          "cursus_ids": [4],
          "marked_at": "2017-09-01T17:52:59.604Z",
          "marked": true,
          "retriable_at": "2017-09-01T17:52:59.556Z"
        },
        {
          "id": 274407,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1296658,
          "project": {
            "id": 190,
            "name": "06",
            "slug": "piscine-c-day-09-06",
            "parent_id": 167
          },
          "cursus_ids": [4],
          "marked_at": "2017-09-01T17:52:59.346Z",
          "marked": true,
          "retriable_at": "2017-09-01T17:52:59.315Z"
        },
        {
          "id": 274396,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1296647,
          "project": {
            "id": 188,
            "name": "04",
            "slug": "piscine-c-day-09-04",
            "parent_id": 167
          },
          "cursus_ids": [4],
          "marked_at": "2017-09-01T17:52:59.838Z",
          "marked": true,
          "retriable_at": "2017-09-01T17:52:59.801Z"
        },
        {
          "id": 274492,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1296743,
          "project": {
            "id": 200,
            "name": "16",
            "slug": "piscine-c-day-09-16",
            "parent_id": 167
          },
          "cursus_ids": [4],
          "marked_at": "2017-09-01T17:52:56.375Z",
          "marked": true,
          "retriable_at": "2017-09-01T17:52:56.351Z"
        },
        {
          "id": 274438,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1296689,
          "project": {
            "id": 194,
            "name": "10",
            "slug": "piscine-c-day-09-10",
            "parent_id": 167
          },
          "cursus_ids": [4],
          "marked_at": "2017-09-01T17:52:58.231Z",
          "marked": true,
          "retriable_at": "2017-09-01T17:52:58.204Z"
        },
        {
          "id": 274409,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1296660,
          "project": {
            "id": 191,
            "name": "07",
            "slug": "piscine-c-day-09-07",
            "parent_id": 167
          },
          "cursus_ids": [4],
          "marked_at": "2017-09-01T17:52:58.995Z",
          "marked": true,
          "retriable_at": "2017-09-01T17:52:58.961Z"
        },
        {
          "id": 280347,
          "occurrence": 0,
          "final_mark": 88,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1302465,
          "project": {
            "id": 405,
            "name": "Exam01",
            "slug": "piscine-c-exam01",
            "parent_id": null
          },
          "cursus_ids": [4],
          "marked_at": "2016-07-13T06:27:42.000Z",
          "marked": true,
          "retriable_at": "2017-06-26T21:47:33.246Z"
        },
        {
          "id": 285243,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1307202,
          "project": {
            "id": 201,
            "name": "17",
            "slug": "piscine-c-day-09-17",
            "parent_id": 167
          },
          "cursus_ids": [4],
          "marked_at": "2017-09-01T17:52:54.464Z",
          "marked": true,
          "retriable_at": "2017-09-01T17:52:54.425Z"
        },
        {
          "id": 285238,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1307197,
          "project": {
            "id": 204,
            "name": "20",
            "slug": "piscine-c-day-09-20",
            "parent_id": 167
          },
          "cursus_ids": [4],
          "marked_at": "2017-09-01T17:52:55.852Z",
          "marked": true,
          "retriable_at": "2017-09-01T17:52:55.827Z"
        },
        {
          "id": 285239,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1307198,
          "project": {
            "id": 207,
            "name": "23",
            "slug": "piscine-c-day-09-23",
            "parent_id": 167
          },
          "cursus_ids": [4],
          "marked_at": "2017-09-01T17:52:55.665Z",
          "marked": true,
          "retriable_at": "2017-09-01T17:52:55.617Z"
        },
        {
          "id": 272717,
          "occurrence": 0,
          "final_mark": 12,
          "status": "finished",
          "validated?": false,
          "current_team_id": 1294940,
          "project": {
            "id": 167,
            "name": "Day 09",
            "slug": "piscine-c-day-09",
            "parent_id": null
          },
          "cursus_ids": [4],
          "marked_at": "2016-07-16T16:11:17.915Z",
          "marked": true,
          "retriable_at": "2016-07-16T16:11:17.892Z"
        },
        {
          "id": 285241,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1307200,
          "project": {
            "id": 205,
            "name": "21",
            "slug": "piscine-c-day-09-21",
            "parent_id": 167
          },
          "cursus_ids": [4],
          "marked_at": "2017-09-01T17:52:55.020Z",
          "marked": true,
          "retriable_at": "2017-09-01T17:52:54.999Z"
        },
        {
          "id": 285240,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1307199,
          "project": {
            "id": 206,
            "name": "22",
            "slug": "piscine-c-day-09-22",
            "parent_id": 167
          },
          "cursus_ids": [4],
          "marked_at": "2017-09-01T17:52:55.260Z",
          "marked": true,
          "retriable_at": "2017-09-01T17:52:55.221Z"
        },
        {
          "id": 1681541,
          "occurrence": 0,
          "final_mark": 69,
          "status": "finished",
          "validated?": true,
          "current_team_id": 2954768,
          "project": {
            "id": 1482,
            "name": "Piscine Ruby on Rails",
            "slug": "42cursus-piscine-ruby-on-rails",
            "parent_id": null
          },
          "cursus_ids": [21],
          "marked_at": "2018-04-24T12:17:53.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 1681528,
          "occurrence": 0,
          "final_mark": 125,
          "status": "finished",
          "validated?": true,
          "current_team_id": 2954755,
          "project": {
            "id": 1402,
            "name": "hypertube",
            "slug": "42cursus-hypertube",
            "parent_id": null
          },
          "cursus_ids": [21],
          "marked_at": "2017-11-11T13:00:09.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 1681540,
          "occurrence": 0,
          "final_mark": 125,
          "status": "finished",
          "validated?": true,
          "current_team_id": 2954766,
          "project": {
            "id": 1418,
            "name": "dr-quine",
            "slug": "42cursus-dr-quine",
            "parent_id": null
          },
          "cursus_ids": [21],
          "marked_at": "2017-09-25T09:06:43.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 1681553,
          "occurrence": 0,
          "final_mark": 125,
          "status": "finished",
          "validated?": true,
          "current_team_id": 2954780,
          "project": {
            "id": 1646,
            "name": "Internship II - Duration",
            "slug": "internship-ii-internship-ii-duration",
            "parent_id": 1644
          },
          "cursus_ids": [21],
          "marked_at": "2018-03-23T14:10:08.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 1681570,
          "occurrence": 0,
          "final_mark": 103,
          "status": "finished",
          "validated?": true,
          "current_team_id": 2954797,
          "project": {
            "id": 1641,
            "name": "internship I - Company Mid Evaluation",
            "slug": "internship-i-internship-i-company-mid-evaluation",
            "parent_id": 1638
          },
          "cursus_ids": [21],
          "marked_at": "2017-10-30T17:30:25.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 1681571,
          "occurrence": 0,
          "final_mark": 118,
          "status": "finished",
          "validated?": true,
          "current_team_id": 2954798,
          "project": {
            "id": 1647,
            "name": "Internship II - Company Mid Evaluation",
            "slug": "internship-ii-internship-ii-company-mid-evaluation",
            "parent_id": 1644
          },
          "cursus_ids": [21],
          "marked_at": "2018-05-28T11:53:57.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 1681555,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 2954782,
          "project": {
            "id": 1608,
            "name": "Day 00",
            "slug": "42cursus-piscine-ruby-on-rails-day-00",
            "parent_id": 1482
          },
          "cursus_ids": [21],
          "marked_at": "2017-09-02T13:20:20.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 1681535,
          "occurrence": 0,
          "final_mark": 123,
          "status": "finished",
          "validated?": true,
          "current_team_id": 2954762,
          "project": {
            "id": 1638,
            "name": "Internship I",
            "slug": "internship-i",
            "parent_id": null
          },
          "cursus_ids": [21],
          "marked_at": "2018-04-17T08:39:55.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 1681534,
          "occurrence": 0,
          "final_mark": 118,
          "status": "finished",
          "validated?": true,
          "current_team_id": 2954760,
          "project": {
            "id": 1401,
            "name": "matcha",
            "slug": "42cursus-matcha",
            "parent_id": null
          },
          "cursus_ids": [21],
          "marked_at": "2017-10-21T13:54:23.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 1681551,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 2954777,
          "project": {
            "id": 1649,
            "name": "Internship II - Peer Video",
            "slug": "internship-ii-internship-ii-peer-video",
            "parent_id": 1644
          },
          "cursus_ids": [21],
          "marked_at": "2018-08-28T13:21:42.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 1681552,
          "occurrence": 0,
          "final_mark": 118,
          "status": "finished",
          "validated?": true,
          "current_team_id": 2954778,
          "project": {
            "id": 1648,
            "name": "Internship II - Company Final Evaluation",
            "slug": "internship-ii-internship-ii-company-final-evaluation",
            "parent_id": 1644
          },
          "cursus_ids": [21],
          "marked_at": "2018-08-24T11:33:09.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 1170756,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": false,
          "current_team_id": 2335272,
          "project": {
            "id": 1190,
            "name": "roger-skyline-1",
            "slug": "roger-skyline-1",
            "parent_id": null
          },
          "cursus_ids": [1],
          "marked_at": "2019-12-21T20:20:59.448Z",
          "marked": true,
          "retriable_at": "2019-12-24T20:20:59.475Z"
        },
        {
          "id": 1681531,
          "occurrence": 0,
          "final_mark": 125,
          "status": "finished",
          "validated?": true,
          "current_team_id": 2954757,
          "project": {
            "id": 1644,
            "name": "Internship II",
            "slug": "internship-ii",
            "parent_id": null
          },
          "cursus_ids": [21],
          "marked_at": "2018-08-28T13:21:43.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 1681530,
          "occurrence": 0,
          "final_mark": 125,
          "status": "finished",
          "validated?": true,
          "current_team_id": 2954756,
          "project": {
            "id": 1405,
            "name": "darkly",
            "slug": "42cursus-darkly",
            "parent_id": null
          },
          "cursus_ids": [21],
          "marked_at": "2017-11-28T18:03:50.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 1681543,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 2954770,
          "project": {
            "id": 1645,
            "name": "internship II - Contract Upload",
            "slug": "internship-ii-internship-ii-contract-upload",
            "parent_id": 1644
          },
          "cursus_ids": [21],
          "marked_at": "2018-03-23T14:10:08.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 1681545,
          "occurrence": 0,
          "final_mark": 125,
          "status": "finished",
          "validated?": true,
          "current_team_id": 2954771,
          "project": {
            "id": 1639,
            "name": "Internship I - Duration",
            "slug": "internship-i-internship-i-duration",
            "parent_id": 1638
          },
          "cursus_ids": [21],
          "marked_at": "2017-07-13T15:24:05.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 1681546,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 2954773,
          "project": {
            "id": 1640,
            "name": "internship I - Contract Upload",
            "slug": "internship-i-internship-i-contract-upload",
            "parent_id": 1638
          },
          "cursus_ids": [21],
          "marked_at": "2017-07-13T15:24:06.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 1681548,
          "occurrence": 0,
          "final_mark": 111,
          "status": "finished",
          "validated?": true,
          "current_team_id": 2954774,
          "project": {
            "id": 1642,
            "name": "internship I - Company Final Evaluation",
            "slug": "internship-i-internship-i-company-final-evaluation",
            "parent_id": 1638
          },
          "cursus_ids": [21],
          "marked_at": "2018-04-17T08:39:55.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 1681549,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 2954775,
          "project": {
            "id": 1643,
            "name": "Internship I - Peer Video",
            "slug": "internship-i-internship-i-peer-video",
            "parent_id": 1638
          },
          "cursus_ids": [21],
          "marked_at": "2018-01-10T11:55:46.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 1681558,
          "occurrence": 0,
          "final_mark": 54,
          "status": "finished",
          "validated?": true,
          "current_team_id": 2954784,
          "project": {
            "id": 1610,
            "name": "Day 02",
            "slug": "42cursus-piscine-ruby-on-rails-day-02",
            "parent_id": 1482
          },
          "cursus_ids": [21],
          "marked_at": "2017-09-02T13:20:48.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 1681559,
          "occurrence": 0,
          "final_mark": 57,
          "status": "finished",
          "validated?": true,
          "current_team_id": 2954786,
          "project": {
            "id": 1611,
            "name": "Day 03",
            "slug": "42cursus-piscine-ruby-on-rails-day-03",
            "parent_id": 1482
          },
          "cursus_ids": [21],
          "marked_at": "2017-09-02T13:21:15.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 1681560,
          "occurrence": 0,
          "final_mark": 52,
          "status": "finished",
          "validated?": true,
          "current_team_id": 2954787,
          "project": {
            "id": 1612,
            "name": "Day 04",
            "slug": "42cursus-piscine-ruby-on-rails-day-04",
            "parent_id": 1482
          },
          "cursus_ids": [21],
          "marked_at": "2017-09-02T13:21:45.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 1681562,
          "occurrence": 0,
          "final_mark": 67,
          "status": "finished",
          "validated?": false,
          "current_team_id": 2954788,
          "project": {
            "id": 1618,
            "name": "Rush 00",
            "slug": "piscine-ruby-on-rails-rush-00",
            "parent_id": 791
          },
          "cursus_ids": [21],
          "marked_at": "2016-12-12T11:14:22.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 1681563,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": false,
          "current_team_id": 2954790,
          "project": {
            "id": 1613,
            "name": "Day 05",
            "slug": "42cursus-piscine-ruby-on-rails-day-05",
            "parent_id": 1482
          },
          "cursus_ids": [21],
          "marked_at": "2017-01-23T15:45:59.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 1681565,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": false,
          "current_team_id": 2954791,
          "project": {
            "id": 1614,
            "name": "Day 06",
            "slug": "42cursus-piscine-ruby-on-rails-day-06",
            "parent_id": 1482
          },
          "cursus_ids": [21],
          "marked_at": "2017-09-02T13:22:49.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 1681566,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": false,
          "current_team_id": 2954793,
          "project": {
            "id": 1615,
            "name": "Day 07",
            "slug": "42cursus-piscine-ruby-on-rails-day-07",
            "parent_id": 1482
          },
          "cursus_ids": [21],
          "marked_at": "2016-12-19T08:51:44.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 1681567,
          "occurrence": 0,
          "final_mark": 60,
          "status": "finished",
          "validated?": true,
          "current_team_id": 2954794,
          "project": {
            "id": 1616,
            "name": "Day 08",
            "slug": "42cursus-piscine-ruby-on-rails-day-08",
            "parent_id": 1482
          },
          "cursus_ids": [21],
          "marked_at": "2016-12-18T10:28:33.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 1681568,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": false,
          "current_team_id": 2954795,
          "project": {
            "id": 1617,
            "name": "Day 09",
            "slug": "42cursus-piscine-ruby-on-rails-day-09",
            "parent_id": 1482
          },
          "cursus_ids": [21],
          "marked_at": "2016-12-19T08:51:36.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 1681569,
          "occurrence": 0,
          "final_mark": 0,
          "status": "finished",
          "validated?": false,
          "current_team_id": 2954796,
          "project": {
            "id": 1619,
            "name": "Rush 01",
            "slug": "piscine-ruby-on-rails-rush-01",
            "parent_id": 791
          },
          "cursus_ids": [21],
          "marked_at": "2018-04-24T12:17:53.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 1681556,
          "occurrence": 0,
          "final_mark": 79,
          "status": "finished",
          "validated?": true,
          "current_team_id": 2954783,
          "project": {
            "id": 1609,
            "name": "Day 01",
            "slug": "42cursus-piscine-ruby-on-rails-day-01",
            "parent_id": 1482
          },
          "cursus_ids": [21],
          "marked_at": "2017-04-14T12:09:05.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        },
        {
          "id": 438788,
          "occurrence": 1,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 1472260,
          "project": {
            "id": 96,
            "name": "Savoir Relier",
            "slug": "savoir-relier",
            "parent_id": null
          },
          "cursus_ids": [1],
          "marked_at": "2016-11-13T17:02:42.006Z",
          "marked": true,
          "retriable_at": "2016-11-13T17:02:40.889Z"
        },
        {
          "id": 1681532,
          "occurrence": 0,
          "final_mark": 100,
          "status": "finished",
          "validated?": true,
          "current_team_id": 2954759,
          "project": {
            "id": 1396,
            "name": "camagru",
            "slug": "42cursus-camagru",
            "parent_id": null
          },
          "cursus_ids": [21],
          "marked_at": "2017-06-26T21:53:01.000Z",
          "marked": true,
          "retriable_at": "2019-12-19T23:00:00.000Z"
        }
      ],
      "languages_users": [
        {
          "id": 131203,
          "language_id": 2,
          "user_id": 19265,
          "position": 1,
          "created_at": "2018-10-19T11:21:57.397Z"
        }
      ],
      "achievements": [
        {
          "id": 116,
          "name": "1.21 Gigawatts ?!",
          "description": "Participer au Time Capsule et se laisser un petit mot.",
          "tier": "easy",
          "kind": "social",
          "visible": true,
          "image": "/uploads/achievement/image/116/SOC014.svg",
          "nbr_of_success": null,
          "users_url": "https://api.intra.42.fr/v2/achievements/116/users"
        },
        {
          "id": 40,
          "name": "404 - Sleep not found",
          "description": "Etre logué 24h de suite. (à bosser, ofc !)",
          "tier": "easy",
          "kind": "scolarity",
          "visible": true,
          "image": "/uploads/achievement/image/40/SCO001.svg",
          "nbr_of_success": null,
          "users_url": "https://api.intra.42.fr/v2/achievements/40/users"
        },
        {
          "id": 41,
          "name": "All work and no play makes Jack a dull boy",
          "description": "Etre logué 90h sur une semaine. ",
          "tier": "easy",
          "kind": "scolarity",
          "visible": true,
          "image": "/uploads/achievement/image/41/SCO001.svg",
          "nbr_of_success": null,
          "users_url": "https://api.intra.42.fr/v2/achievements/41/users"
        },
        {
          "id": 107,
          "name": "And now my watch begins",
          "description": "Rejoindre les tuteurs.",
          "tier": "none",
          "kind": "scolarity",
          "visible": true,
          "image": "/uploads/achievement/image/107/SCO0017.svg",
          "nbr_of_success": null,
          "users_url": "https://api.intra.42.fr/v2/achievements/107/users"
        },
        {
          "id": 17,
          "name": "Bonus Hunter",
          "description": "Valider 1 projet avec la note maximum.",
          "tier": "easy",
          "kind": "project",
          "visible": false,
          "image": "/uploads/achievement/image/17/PRO005.svg",
          "nbr_of_success": 1,
          "users_url": "https://api.intra.42.fr/v2/achievements/17/users"
        },
        {
          "id": 18,
          "name": "Bonus Hunter",
          "description": "Valider 3 projets avec la note maximum.",
          "tier": "medium",
          "kind": "project",
          "visible": false,
          "image": "/uploads/achievement/image/18/PRO005.svg",
          "nbr_of_success": 3,
          "users_url": "https://api.intra.42.fr/v2/achievements/18/users"
        },
        {
          "id": 114,
          "name": "Business Angel",
          "description": "Valider un partenariat.",
          "tier": "none",
          "kind": "project",
          "visible": true,
          "image": "/uploads/achievement/image/114/PRO014.svg",
          "nbr_of_success": null,
          "users_url": "https://api.intra.42.fr/v2/achievements/114/users"
        },
        {
          "id": 4,
          "name": "Code Explorer",
          "description": "Valider son premier projet.",
          "tier": "none",
          "kind": "project",
          "visible": true,
          "image": "/uploads/achievement/image/4/PRO002.svg",
          "nbr_of_success": 1,
          "users_url": "https://api.intra.42.fr/v2/achievements/4/users"
        },
        {
          "id": 5,
          "name": "Code Explorer",
          "description": "Valider 3 projets.",
          "tier": "none",
          "kind": "project",
          "visible": true,
          "image": "/uploads/achievement/image/5/PRO002.svg",
          "nbr_of_success": 3,
          "users_url": "https://api.intra.42.fr/v2/achievements/5/users"
        },
        {
          "id": 6,
          "name": "Code Explorer",
          "description": "Valider 10 projets.",
          "tier": "none",
          "kind": "project",
          "visible": true,
          "image": "/uploads/achievement/image/6/PRO002.svg",
          "nbr_of_success": 10,
          "users_url": "https://api.intra.42.fr/v2/achievements/6/users"
        },
        {
          "id": 7,
          "name": "Code Explorer",
          "description": "Valider 21 projets.",
          "tier": "none",
          "kind": "project",
          "visible": true,
          "image": "/uploads/achievement/image/7/PRO002.svg",
          "nbr_of_success": 21,
          "users_url": "https://api.intra.42.fr/v2/achievements/7/users"
        },
        {
          "id": 65,
          "name": "Come to the dark side, we have cookies",
          "description": "Devenir bocalien.",
          "tier": "none",
          "kind": "scolarity",
          "visible": true,
          "image": "/uploads/achievement/image/65/SCO010.svg",
          "nbr_of_success": null,
          "users_url": "https://api.intra.42.fr/v2/achievements/65/users"
        },
        {
          "id": 44,
          "name": "Curious wanderer",
          "description": "S'être logué une fois dans chaque cluster.",
          "tier": "none",
          "kind": "scolarity",
          "visible": false,
          "image": "/uploads/achievement/image/44/SCO002.svg",
          "nbr_of_success": null,
          "users_url": "https://api.intra.42.fr/v2/achievements/44/users"
        },
        {
          "id": 46,
          "name": "Film buff",
          "description": "Regarder 1 video sur l'e-learning.",
          "tier": "none",
          "kind": "pedagogy",
          "visible": false,
          "image": "/uploads/achievement/image/46/PED005.svg",
          "nbr_of_success": 1,
          "users_url": "https://api.intra.42.fr/v2/achievements/46/users"
        },
        {
          "id": 47,
          "name": "Film buff",
          "description": "Regarder 3 videos sur l'e-learning.",
          "tier": "none",
          "kind": "pedagogy",
          "visible": false,
          "image": "/uploads/achievement/image/47/PED005.svg",
          "nbr_of_success": 3,
          "users_url": "https://api.intra.42.fr/v2/achievements/47/users"
        },
        {
          "id": 45,
          "name": "Home is where the code is",
          "description": "S'être logué dans le même cluster un mois de suite.",
          "tier": "none",
          "kind": "scolarity",
          "visible": true,
          "image": "/uploads/achievement/image/45/SCO002.svg",
          "nbr_of_success": null,
          "users_url": "https://api.intra.42.fr/v2/achievements/45/users"
        },
        {
          "id": 103,
          "name": "I am the watcher on the walls",
          "description": "Surveiller 1 examen en tant que tuteur.",
          "tier": "none",
          "kind": "scolarity",
          "visible": true,
          "image": "/uploads/achievement/image/103/SCO0016.svg",
          "nbr_of_success": 1,
          "users_url": "https://api.intra.42.fr/v2/achievements/103/users"
        },
        {
          "id": 31,
          "name": "I found the answer",
          "description": "Valider le level 21 et être prêt à affronter le monde extérieur !",
          "tier": "none",
          "kind": "pedagogy",
          "visible": true,
          "image": "/uploads/achievement/image/31/PED003.svg",
          "nbr_of_success": null,
          "users_url": "https://api.intra.42.fr/v2/achievements/31/users"
        },
        {
          "id": 82,
          "name": "I have no idea what I'm doing",
          "description": "Faire une soutenance sans avoir validé le projet.",
          "tier": "none",
          "kind": "pedagogy",
          "visible": true,
          "image": "/uploads/achievement/image/82/PED011.svg",
          "nbr_of_success": null,
          "users_url": "https://api.intra.42.fr/v2/achievements/82/users"
        },
        {
          "id": 109,
          "name": "I’ll make him an offer he can’t refuse",
          "description": "Participer au programme de parrainage en tant que parrain.",
          "tier": "none",
          "kind": "pedagogy",
          "visible": true,
          "image": "/uploads/achievement/image/109/PED014.svg",
          "nbr_of_success": null,
          "users_url": "https://api.intra.42.fr/v2/achievements/109/users"
        },
        {
          "id": 84,
          "name": "I'm reliable !",
          "description": "Participer à 21 soutenances d'affilée sans en manquer aucune.",
          "tier": "easy",
          "kind": "pedagogy",
          "visible": true,
          "image": "/uploads/achievement/image/84/PED009.svg",
          "nbr_of_success": 21,
          "users_url": "https://api.intra.42.fr/v2/achievements/84/users"
        },
        {
          "id": 87,
          "name": "I post, therefore I am",
          "description": "Poster 1 message sur le forum.",
          "tier": "none",
          "kind": "social",
          "visible": false,
          "image": "/uploads/achievement/image/87/SOC005.svg",
          "nbr_of_success": 1,
          "users_url": "https://api.intra.42.fr/v2/achievements/87/users"
        },
        {
          "id": 36,
          "name": "It's a rich man's world",
          "description": "Avoir 100 points de wallet.",
          "tier": "none",
          "kind": "social",
          "visible": true,
          "image": "/uploads/achievement/image/36/SOC004.svg",
          "nbr_of_success": 100,
          "users_url": "https://api.intra.42.fr/v2/achievements/36/users"
        },
        {
          "id": 37,
          "name": "It's a rich man's world",
          "description": "Avoir 200 points de wallet.",
          "tier": "none",
          "kind": "social",
          "visible": true,
          "image": "/uploads/achievement/image/37/SOC004.svg",
          "nbr_of_success": 200,
          "users_url": "https://api.intra.42.fr/v2/achievements/37/users"
        },
        {
          "id": 155,
          "name": "Je voudrais un croissant",
          "description": "Visiter le campus de Paris",
          "tier": "none",
          "kind": "scolarity",
          "visible": true,
          "image": "/uploads/achievement/image/155/BADGE_SCOLARITY_paris.svg",
          "nbr_of_success": null,
          "users_url": "https://api.intra.42.fr/v2/achievements/155/users"
        },
        {
          "id": 88,
          "name": "Love me, I'm famous",
          "description": "Avoir été upvoté 1 fois sur le forum.",
          "tier": "none",
          "kind": "social",
          "visible": true,
          "image": "/uploads/achievement/image/88/SOC006.svg",
          "nbr_of_success": 1,
          "users_url": "https://api.intra.42.fr/v2/achievements/88/users"
        },
        {
          "id": 94,
          "name": "Love me, I'm famous",
          "description": "Avoir été upvoté 10 fois sur le forum.",
          "tier": "none",
          "kind": "social",
          "visible": true,
          "image": "/uploads/achievement/image/94/SOC006.svg",
          "nbr_of_success": 10,
          "users_url": "https://api.intra.42.fr/v2/achievements/94/users"
        },
        {
          "id": 95,
          "name": "Love me, I'm famous",
          "description": "Avoir été upvoté 42 fois sur le forum. Ne seront comptés que 25 upvotes par personne au maximum.",
          "tier": "none",
          "kind": "social",
          "visible": false,
          "image": "/uploads/achievement/image/95/SOC006.svg",
          "nbr_of_success": 42,
          "users_url": "https://api.intra.42.fr/v2/achievements/95/users"
        },
        {
          "id": 25,
          "name": "Rigorous Basterd",
          "description": "Valider 3 projets d'affilée (journées de piscines comprises).",
          "tier": "none",
          "kind": "project",
          "visible": true,
          "image": "/uploads/achievement/image/25/PRO010.svg",
          "nbr_of_success": 3,
          "users_url": "https://api.intra.42.fr/v2/achievements/25/users"
        },
        {
          "id": 26,
          "name": "Rigorous Basterd",
          "description": "Valider 10 projets d'affilée (journées de piscines comprises).",
          "tier": "easy",
          "kind": "project",
          "visible": true,
          "image": "/uploads/achievement/image/26/PRO010.svg",
          "nbr_of_success": 10,
          "users_url": "https://api.intra.42.fr/v2/achievements/26/users"
        },
        {
          "id": 27,
          "name": "Rigorous Basterd",
          "description": "Valider 21 projets d'affilée (journées de piscines comprises).",
          "tier": "medium",
          "kind": "project",
          "visible": true,
          "image": "/uploads/achievement/image/27/PRO010.svg",
          "nbr_of_success": 21,
          "users_url": "https://api.intra.42.fr/v2/achievements/27/users"
        },
        {
          "id": 28,
          "name": "Rigorous Basterd",
          "description": "Valider 42 projets d'affilée (journées de piscines comprises).",
          "tier": "hard",
          "kind": "project",
          "visible": true,
          "image": "/uploads/achievement/image/28/PRO010.svg",
          "nbr_of_success": 42,
          "users_url": "https://api.intra.42.fr/v2/achievements/28/users"
        },
        {
          "id": 39,
          "name": "Sleep is for the weak",
          "description": "Obtenir les achievements \"404 - Sleep not found\" et \"In the name of Nicolas !\"",
          "tier": "none",
          "kind": "scolarity",
          "visible": true,
          "image": "/uploads/achievement/image/39/SCO001.svg",
          "nbr_of_success": null,
          "users_url": "https://api.intra.42.fr/v2/achievements/39/users"
        },
        {
          "id": 115,
          "name": "Venture Capitalist",
          "description": "Valider un partenariat avec la note 125.",
          "tier": "none",
          "kind": "project",
          "visible": true,
          "image": "/uploads/achievement/image/115/PRO016.svg",
          "nbr_of_success": null,
          "users_url": "https://api.intra.42.fr/v2/achievements/115/users"
        },
        {
          "id": 1,
          "name": "Welcome, Cadet !",
          "description": "Tu as réussi ta piscine C. Bienvenue à 42 !",
          "tier": "none",
          "kind": "project",
          "visible": true,
          "image": "/uploads/achievement/image/1/PRO001.svg",
          "nbr_of_success": null,
          "users_url": "https://api.intra.42.fr/v2/achievements/1/users"
        }
      ],
      "titles": [
        {
          "id": 12,
          "name": "Altruist %login"
        },
        {
          "id": 42,
          "name": "Venture Capitalist %login"
        },
        {
          "id": 82,
          "name": "[DEPRECATED] %login"
        }
      ],
      "titles_users": [
        {
          "id": 499,
          "user_id": 19265,
          "title_id": 12,
          "selected": false
        },
        {
          "id": 1178,
          "user_id": 19265,
          "title_id": 42,
          "selected": false
        },
        {
          "id": 3571,
          "user_id": 19265,
          "title_id": 82,
          "selected": false
        }
      ],
      "partnerships": [
        {
          "id": 366,
          "name": "42cursus - [bocal] Développement web 6 mois",
          "slug": "42cursus-bocal-developpement-web-6-mois",
          "difficulty": 42000,
          "url": "https://api.intra.42.fr/v2/partnerships/42cursus-bocal-developpement-web-6-mois",
          "partnerships_users_url": "https://api.intra.42.fr/v2/partnerships/42cursus-bocal-developpement-web-6-mois/partnerships_users",
          "partnerships_skills": [
            {
              "id": 850,
              "partnership_id": 366,
              "skill_id": 7,
              "value": 4200.0,
              "created_at": "2019-12-20T11:33:20.393Z",
              "updated_at": "2019-12-20T11:33:20.393Z"
            },
            {
              "id": 849,
              "partnership_id": 366,
              "skill_id": 6,
              "value": 18900.0,
              "created_at": "2019-12-20T11:33:20.391Z",
              "updated_at": "2019-12-20T11:33:20.391Z"
            },
            {
              "id": 848,
              "partnership_id": 366,
              "skill_id": 16,
              "value": 10500.0,
              "created_at": "2019-12-20T11:33:20.389Z",
              "updated_at": "2019-12-20T11:33:20.389Z"
            },
            {
              "id": 847,
              "partnership_id": 366,
              "skill_id": 12,
              "value": 8400.0,
              "created_at": "2019-12-20T11:33:20.387Z",
              "updated_at": "2019-12-20T11:33:20.387Z"
            }
          ]
        },
        {
          "id": 45,
          "name": "[bocal] Développement web 6 mois",
          "slug": "bocal-developpement-web-6-mois",
          "difficulty": 1000,
          "url": "https://api.intra.42.fr/v2/partnerships/bocal-developpement-web-6-mois",
          "partnerships_users_url": "https://api.intra.42.fr/v2/partnerships/bocal-developpement-web-6-mois/partnerships_users",
          "partnerships_skills": [
            {
              "id": 106,
              "partnership_id": 45,
              "skill_id": 12,
              "value": 200.0,
              "created_at": "2016-02-25T13:55:06.254Z",
              "updated_at": "2016-02-25T13:55:06.254Z"
            },
            {
              "id": 107,
              "partnership_id": 45,
              "skill_id": 16,
              "value": 250.0,
              "created_at": "2016-02-25T13:55:06.264Z",
              "updated_at": "2016-02-25T13:55:06.264Z"
            },
            {
              "id": 108,
              "partnership_id": 45,
              "skill_id": 6,
              "value": 450.0,
              "created_at": "2016-02-25T13:55:06.272Z",
              "updated_at": "2016-02-25T13:55:06.272Z"
            },
            {
              "id": 109,
              "partnership_id": 45,
              "skill_id": 7,
              "value": 100.0,
              "created_at": "2016-02-25T13:55:06.280Z",
              "updated_at": "2016-02-25T13:55:06.280Z"
            }
          ]
        }
      ],
      "patroned": [],
      "patroning": [
        {
          "id": 641,
          "user_id": 26286,
          "godfather_id": 19265,
          "ongoing": true,
          "created_at": "2017-11-08T12:09:36.343Z",
          "updated_at": "2020-10-28T06:11:33.003Z"
        },
        {
          "id": 746,
          "user_id": 26384,
          "godfather_id": 19265,
          "ongoing": true,
          "created_at": "2017-11-08T17:21:54.330Z",
          "updated_at": "2020-10-28T06:11:33.549Z"
        },
        {
          "id": 640,
          "user_id": 27119,
          "godfather_id": 19265,
          "ongoing": true,
          "created_at": "2017-11-08T12:09:36.143Z",
          "updated_at": "2020-10-28T06:11:33.181Z"
        },
        {
          "id": 642,
          "user_id": 28830,
          "godfather_id": 19265,
          "ongoing": true,
          "created_at": "2017-11-08T12:09:36.523Z",
          "updated_at": "2020-10-28T06:11:33.212Z"
        }
      ],
      "expertises_users": [
        {
          "id": 22552,
          "expertise_id": 30,
          "interested": false,
          "value": 3,
          "contact_me": false,
          "created_at": "2018-07-22T11:49:26.596Z",
          "user_id": 19265
        },
        {
          "id": 19215,
          "expertise_id": 26,
          "interested": false,
          "value": 3,
          "contact_me": false,
          "created_at": "2018-02-22T14:48:07.598Z",
          "user_id": 19265
        },
        {
          "id": 19213,
          "expertise_id": 12,
          "interested": false,
          "value": 4,
          "contact_me": false,
          "created_at": "2018-02-22T10:32:13.223Z",
          "user_id": 19265
        },
        {
          "id": 19212,
          "expertise_id": 13,
          "interested": false,
          "value": 3,
          "contact_me": false,
          "created_at": "2018-02-22T10:31:42.703Z",
          "user_id": 19265
        },
        {
          "id": 19211,
          "expertise_id": 15,
          "interested": false,
          "value": 2,
          "contact_me": false,
          "created_at": "2018-02-22T10:31:16.196Z",
          "user_id": 19265
        },
        {
          "id": 19210,
          "expertise_id": 33,
          "interested": false,
          "value": 4,
          "contact_me": false,
          "created_at": "2018-02-22T10:31:02.503Z",
          "user_id": 19265
        },
        {
          "id": 19209,
          "expertise_id": 31,
          "interested": false,
          "value": 5,
          "contact_me": false,
          "created_at": "2018-02-22T10:30:56.816Z",
          "user_id": 19265
        }
      ],
      "roles": [],
      "campus": [
        {
          "id": 1,
          "name": "Paris",
          "time_zone": "Europe/Paris",
          "language": {
            "id": 1,
            "name": "Français",
            "identifier": "fr",
            "created_at": "2014-11-02T16:43:38.466Z",
            "updated_at": "2021-04-14T12:59:04.679Z"
          },
          "users_count": 21241,
          "vogsphere_id": 1,
          "country": "France",
          "address": "96, boulevard Bessières",
          "zip": "75017",
          "city": "Paris",
          "website": "http://www.42.fr/",
          "facebook": "https://facebook.com/42born2code",
          "twitter": "https://twitter.com/42born2code",
          "active": true,
          "email_extension": "42.fr",
          "default_hidden_phone": false
        }
      ],
      "campus_users": [
        {
          "id": 8379,
          "user_id": 19265,
          "campus_id": 1,
          "is_primary": true
        }
      ]
    }
  }
}
```

## Licence

The MIT License (MIT)

Copyright (c) 2015 Samy KACIMI

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
