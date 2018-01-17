# Omniauth Marvin

[![Build Status](https://travis-ci.org/fakenine/omniauth-marvin.svg)](https://travis-ci.org/fakenine/omniauth-marvin) [![Maintainability](https://api.codeclimate.com/v1/badges/3c2ac09cff4d46183947/maintainability)](https://codeclimate.com/github/fakenine/omniauth-marvin/maintainability) [![Coverage Status](https://coveralls.io/repos/fakenine/omniauth-marvin/badge.svg?branch=master&service=github)](https://coveralls.io/github/fakenine/omniauth-marvin?branch=master)

OmniAuth OAuth2 strategy for 42 School.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'omniauth-marvin', '~> 1.0.2'
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
rails g migration AddNicknameToUsers nickname:string
rails g migration AddOmniauthToUsers provider:index uid:index
rake db:migrate
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
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: [:marvin]
end
```

#### Add the from_omniauth class method to the user model

`app/models/user.rb`

Example:

```ruby
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0,20]
      user.nickname = auth.info.nickname
    end
  end
```

#### Implement a callback in the routes

`config/routes.rb`

```ruby
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }
```

#### Create the callbacks controller

`app/controllers/users/omniauth_callbacks_controller.rb`

Example:

```ruby
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def marvin
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      sign_in_and_redirect @user, :event => :authentication
      set_flash_message(:notice, :success, :kind => "42") if is_navigational_format?
    else
      session["devise.marvin_data"] = request.env["omniauth.auth"]
      redirect_to new_user_registration_url
    end
  end
end
```

#### Add the Sign Out route

`config/routes.rb`

```ruby
  devise_scope :user do
    delete 'sign_out', :to => 'devise/sessions#destroy', :as => :destroy_user_session_path
  end
```

#### Login/logout links

Here's a (very) basic example for login/logout links in the views

```
  <%= link_to "Sign in with 42", user_omniauth_authorize_path(:marvin) %>
```

```
  <%= link_to "Sign out", destroy_user_session_path, :method => :delete %>
```


#### More info

This section about devise and Omniauth was written with the help of devise documentation.
More info about devise and Omniauth on [their documentation](https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview "their documentation").

## Auth hash

Here's an example of the auth hash available in request.env['omniauth.auth']:

```json
{
	"provider": "marvin",
	"uid": 12345,
	"info": {
		"name": "Samy KACIMI",
		"email": "skacimi@student.42.fr",
		"nickname": "skacimi",
		"location": null,
		"image": "https://cdn.42.fr/userprofil/profilview/skacimi.jpg",
		"phone": null,
		"urls": {
			"Profile": "https://api.intrav2.42.fr/v2/users/skacimi"
		}
	},
	"credentials": {
		"token": "a1b2c3d4e5f6...",
		"expires_at": 1443035254,
		"expires": true
	},
	"extra": {
		"raw_info": {
			"id": 12345,
			"alias": [
				"samy.kacimi@student.42.fr",
				"kacimi.samy@student.42.fr",
				"skacimi@student.42.fr"
			],
			"email": "skacimi@student.42.fr",
			"login": "skacimi",
			"url": "https://api.intrav2.42.fr/v2/users/skacimi",
			"mobile": null,
			"displayname": "Samy KACIMI",
			"image_url": "https://cdn.42.fr/userprofil/profilview/skacimi.jpg",
			"staff?": false,
			"correction_point": 7,
			"location": null,
			"campus": {
				"id": 1,
				"name": "Paris",
				"created_at": "2015-05-19T12:53:31.459+02:00",
				"updated_at": "2015-07-20T19:28:05.730+02:00",
				"time_zone": "Paris",
				"language_id": 1,
				"slug": "paris"
			},
			"wallet": 70,
			"groups": [

			],
			"cursus": {
				"cursus": {
					"id": 1,
					"name": "42",
					"created_at": "2014-11-02T17:43:38.480+01:00",
					"updated_at": "2015-07-21T14:31:01.625+02:00",
					"slug": "42"
				},
				"end_at": null,
				"level": 7.15,
				"grade": "Midshipman",
				"projects": [
					{
						"name": "Introduction to Wordpress",
						"id": 14,
						"slug": "rushes-introduction-to-wordpress",
						"final_mark": 84,
						"occurrence": 0,
						"retriable_at": null,
						"teams_ids": [
							4017
						]
					},
					{
						"name": "Push_swap",
						"id": 27,
						"slug": "push_swap",
						"final_mark": 84,
						"occurrence": 1,
						"retriable_at": "2015-03-24T20:13:00.000+01:00",
						"teams_ids": [
							55646,
							60613
						]
					},
					{
						"name": "Piscine PHP",
						"id": 48,
						"slug": "piscine-php",
						"final_mark": 81,
						"occurrence": 0,
						"retriable_at": "2015-03-30T17:40:57.000+02:00",
						"teams_ids": [
							64600
						]
					},
					{
						"name": "D06",
						"id": 55,
						"slug": "piscine-php-d06",
						"final_mark": 13,
						"occurrence": 0,
						"retriable_at": "2015-03-30T17:41:30.000+02:00",
						"teams_ids": [
							64607
						]
					},
					{
						"name": "Wolf3d",
						"id": 8,
						"slug": "wolf3d",
						"final_mark": 91,
						"occurrence": 0,
						"retriable_at": "2015-04-04T11:57:10.000+02:00",
						"teams_ids": [
							53923
						]
					},
					{
						"name": "D09",
						"id": 58,
						"slug": "piscine-php-d09",
						"final_mark": 58,
						"occurrence": 0,
						"retriable_at": "2015-03-30T17:42:10.000+02:00",
						"teams_ids": [
							64610
						]
					},
					{
						"name": "Libft",
						"id": 1,
						"slug": "libft",
						"final_mark": 103,
						"occurrence": 2,
						"retriable_at": "2015-01-29T14:55:48.000+01:00",
						"teams_ids": [
							117,
							6157,
							54350
						]
					},
					{
						"name": "Fract'ol",
						"id": 15,
						"slug": "fract-ol",
						"final_mark": 102,
						"occurrence": 0,
						"retriable_at": "2015-04-02T14:11:59.000+02:00",
						"teams_ids": [
							60569
						]
					},
					{
						"name": "First Internship",
						"id": 118,
						"slug": "first-internship",
						"final_mark": null,
						"occurrence": 0,
						"retriable_at": null,
						"teams_ids": [
							84976
						]
					},
					{
						"name": "LibftASM",
						"id": 79,
						"slug": "libftasm",
						"final_mark": 100,
						"occurrence": 0,
						"retriable_at": "2015-03-06T17:03:47.000+01:00",
						"teams_ids": [
							57132
						]
					},
					{
						"name": "C Exam - Beginner",
						"id": 11,
						"slug": "c-exam-beginner",
						"final_mark": 80,
						"occurrence": 13,
						"retriable_at": "2015-05-27T18:33:17.000+02:00",
						"teams_ids": [
							3107,
							5187,
							56010,
							59778,
							60718,
							61716,
							62922,
							63373,
							75451,
							78206,
							78665,
							83011,
							83635,
							84658
						]
					},
					{
						"name": "Duration",
						"id": 140,
						"slug": "first-internship-duration",
						"final_mark": null,
						"occurrence": 0,
						"retriable_at": null,
						"teams_ids": [
							95077
						]
					},
					{
						"name": "Introduction to iOS",
						"id": 18,
						"slug": "rushes-introduction-to-ios",
						"final_mark": 84,
						"occurrence": 0,
						"retriable_at": "2014-12-28T23:09:51.910+01:00",
						"teams_ids": [
							4669
						]
					},
					{
						"name": "FdF",
						"id": 4,
						"slug": "fdf",
						"final_mark": 103,
						"occurrence": 0,
						"retriable_at": "2015-01-05T18:32:46.764+01:00",
						"teams_ids": [
							2960
						]
					},
					{
						"name": "Contract Upload",
						"id": 119,
						"slug": "first-internship-contract-upload",
						"final_mark": 100,
						"occurrence": 0,
						"retriable_at": "2015-05-30T13:28:06.000+02:00",
						"teams_ids": [
							85014
						]
					},
					{
						"name": "Rush00",
						"id": 59,
						"slug": "piscine-php-rush00",
						"final_mark": 69,
						"occurrence": 0,
						"retriable_at": "2015-04-10T18:55:10.000+02:00",
						"teams_ids": [
							76109
						]
					},
					{
						"name": "Rush01",
						"id": 60,
						"slug": "piscine-php-rush01",
						"final_mark": 0,
						"occurrence": 0,
						"retriable_at": "2015-04-16T16:49:32.000+02:00",
						"teams_ids": [
							77242
						]
					},
					{
						"name": "D01",
						"id": 50,
						"slug": "piscine-php-d01",
						"final_mark": 45,
						"occurrence": 0,
						"retriable_at": null,
						"teams_ids": [
							64602
						]
					},
					{
						"name": "D07",
						"id": 56,
						"slug": "piscine-php-d07",
						"final_mark": 75,
						"occurrence": 0,
						"retriable_at": "2015-03-30T17:42:00.000+02:00",
						"teams_ids": [
							64608
						]
					},
					{
						"name": "D04",
						"id": 53,
						"slug": "piscine-php-d04",
						"final_mark": 100,
						"occurrence": 0,
						"retriable_at": null,
						"teams_ids": [
							64605
						]
					},
					{
						"name": "D05",
						"id": 54,
						"slug": "piscine-php-d05",
						"final_mark": 70,
						"occurrence": 0,
						"retriable_at": "2015-03-30T17:41:55.000+02:00",
						"teams_ids": [
							64606
						]
					},
					{
						"name": "wong_kar_wai",
						"id": 93,
						"slug": "rushes-wong_kar_wai",
						"final_mark": 0,
						"occurrence": 0,
						"retriable_at": null,
						"teams_ids": [
							58895
						]
					},
					{
						"name": "Get_Next_Line",
						"id": 2,
						"slug": "get_next_line",
						"final_mark": 102,
						"occurrence": 0,
						"retriable_at": "2014-11-22T18:29:02.195+01:00",
						"teams_ids": [
							1241
						]
					},
					{
						"name": "D08",
						"id": 57,
						"slug": "piscine-php-d08",
						"final_mark": 0,
						"occurrence": 0,
						"retriable_at": "2015-03-30T17:41:36.000+02:00",
						"teams_ids": [
							64609
						]
					},
					{
						"name": "ft_ls",
						"id": 3,
						"slug": "ft_ls",
						"final_mark": 0,
						"occurrence": 0,
						"retriable_at": "2015-01-17T19:13:33.000+01:00",
						"teams_ids": [
							1971
						]
					},
					{
						"name": "D02",
						"id": 51,
						"slug": "piscine-php-d02",
						"final_mark": 13,
						"occurrence": 0,
						"retriable_at": "2015-03-30T17:41:17.000+02:00",
						"teams_ids": [
							64603
						]
					},
					{
						"name": "Rushes",
						"id": 61,
						"slug": "rushes",
						"final_mark": null,
						"occurrence": 0,
						"retriable_at": null,
						"teams_ids": [

						]
					},
					{
						"name": "D03",
						"id": 52,
						"slug": "piscine-php-d03",
						"final_mark": 100,
						"occurrence": 0,
						"retriable_at": null,
						"teams_ids": [
							64604
						]
					},
					{
						"name": "Savoir Relier",
						"id": 96,
						"slug": "savoir-relier",
						"final_mark": 100,
						"occurrence": 0,
						"retriable_at": null,
						"teams_ids": [
							62145
						]
					},
					{
						"name": "Arkanoid",
						"id": 141,
						"slug": "rushes-arkanoid",
						"final_mark": 0,
						"occurrence": 0,
						"retriable_at": null,
						"teams_ids": [
							79069
						]
					},
					{
						"name": "D00",
						"id": 49,
						"slug": "piscine-php-d00",
						"final_mark": 118,
						"occurrence": 0,
						"retriable_at": null,
						"teams_ids": [
							64601
						]
					},
					{
						"name": "ft_sh1",
						"id": 7,
						"slug": "ft_sh1",
						"final_mark": 97,
						"occurrence": 0,
						"retriable_at": "2015-02-10T16:24:33.000+01:00",
						"teams_ids": [
							4776
						]
					}
				],
				"skills": [
					{
						"id": 2,
						"name": "Imperative programming",
						"level": 6.39
					},
					{
						"id": 1,
						"name": "Algorithms & AI",
						"level": 6.2
					},
					{
						"id": 5,
						"name": "Graphics",
						"level": 4.06
					},
					{
						"id": 3,
						"name": "Rigor",
						"level": 3.95
					},
					{
						"id": 4,
						"name": "Unix",
						"level": 1.8
					},
					{
						"id": 6,
						"name": "Web",
						"level": 1.35
					},
					{
						"id": 17,
						"name": "Object-oriented programming",
						"level": 0.63
					},
					{
						"id": 14,
						"name": "Adaptation & creativity",
						"level": 0.34
					},
					{
						"id": 12,
						"name": "DB & Data",
						"level": 0.21
					},
					{
						"id": 10,
						"name": "Network & system administration",
						"level": 0.21
					},
					{
						"id": 15,
						"name": "Technology integration",
						"level": 0.1
					}
				]
			},
			"achievements": [
				{
					"id": 96,
					"name": "Love me, I'm famous",
					"description": "Avoir été upvoté 100 fois sur le forum.",
					"users_url": "https://api.intrav2.42.fr/v2/achievements/96/users"
				},
				{
					"id": 95,
					"name": "Love me, I'm famous",
					"description": "Avoir été upvoté 42 fois sur le forum.",
					"users_url": "https://api.intrav2.42.fr/v2/achievements/95/users"
				},
				{
					"id": 94,
					"name": "Love me, I'm famous",
					"description": "Avoir été upvoté 10 fois sur le forum.",
					"users_url": "https://api.intrav2.42.fr/v2/achievements/94/users"
				},
				{
					"id": 45,
					"name": "Home is where the code is",
					"description": "S'être logué dans le même cluster un mois de suite.",
					"users_url": "https://api.intrav2.42.fr/v2/achievements/45/users"
				},
				{
					"id": 41,
					"name": "In the name of Nicolas",
					"description": "Etre logué 90h sur une semaine. (à bosser, comme Nicolas vous l'a conseillé !)",
					"users_url": "https://api.intrav2.42.fr/v2/achievements/41/users"
				},
				{
					"id": 90,
					"name": "I post, therefore I am",
					"description": "Poster 10 messages sur le forum.",
					"users_url": "https://api.intrav2.42.fr/v2/achievements/90/users"
				},
				{
					"id": 1,
					"name": "Welcome, Cadet !",
					"description": "Tu as réussi ta piscine C. Bienvenue à 42 !",
					"users_url": "https://api.intrav2.42.fr/v2/achievements/1/users"
				},
				{
					"id": 57,
					"name": "Attendee",
					"description": "Assister à 21 conférences.",
					"users_url": "https://api.intrav2.42.fr/v2/achievements/57/users"
				},
				{
					"id": 56,
					"name": "Attendee",
					"description": "Assister à 10 conférences.",
					"users_url": "https://api.intrav2.42.fr/v2/achievements/56/users"
				},
				{
					"id": 55,
					"name": "Attendee",
					"description": "Assister à 3 conférences.",
					"users_url": "https://api.intrav2.42.fr/v2/achievements/55/users"
				},
				{
					"id": 54,
					"name": "Attendee",
					"description": "Assister à une conférence.",
					"users_url": "https://api.intrav2.42.fr/v2/achievements/54/users"
				},
				{
					"id": 84,
					"name": "I'm reliable !",
					"description": "Participer à 21 soutenances d'affilée sans en manquer aucune.",
					"users_url": "https://api.intrav2.42.fr/v2/achievements/84/users"
				},
				{
					"id": 91,
					"name": "I post, therefore I am",
					"description": "Poster 42 messages sur le forum.",
					"users_url": "https://api.intrav2.42.fr/v2/achievements/91/users"
				},
				{
					"id": 4,
					"name": "Code Explorer",
					"description": "Valider son premier projet.",
					"users_url": "https://api.intrav2.42.fr/v2/achievements/4/users"
				},
				{
					"id": 6,
					"name": "Code Explorer",
					"description": "Valider 10 projets.",
					"users_url": "https://api.intrav2.42.fr/v2/achievements/6/users"
				},
				{
					"id": 5,
					"name": "Code Explorer",
					"description": "Valider 3 projets.",
					"users_url": "https://api.intrav2.42.fr/v2/achievements/5/users"
				},
				{
					"id": 17,
					"name": "Bonus Hunter",
					"description": "Valider 1 projet avec le maximum de bonus.",
					"users_url": "https://api.intrav2.42.fr/v2/achievements/17/users"
				},
				{
					"id": 25,
					"name": "Rigorous Basterd",
					"description": "Valider 3 projets d'affilée (journées de piscines comprises).",
					"users_url": "https://api.intrav2.42.fr/v2/achievements/25/users"
				},
				{
					"id": 48,
					"name": "Film buff",
					"description": "Regarder 10 videos sur l'e-learning.",
					"users_url": "https://api.intrav2.42.fr/v2/achievements/48/users"
				},
				{
					"id": 82,
					"name": "I have no idea what I'm doing",
					"description": "Faire une soutenance sans avoir validé le projet.",
					"users_url": "https://api.intrav2.42.fr/v2/achievements/82/users"
				},
				{
					"id": 47,
					"name": "Film buff",
					"description": "Regarder 3 videos sur l'e-learning.",
					"users_url": "https://api.intrav2.42.fr/v2/achievements/47/users"
				},
				{
					"id": 87,
					"name": "I post, therefore I am",
					"description": "Poster 1 message sur le forum.",
					"users_url": "https://api.intrav2.42.fr/v2/achievements/87/users"
				},
				{
					"id": 79,
					"name": "Perfect examiner",
					"description": "Avoir un feedback correcteur à 100% sur 10 soutenances d'affilée.",
					"users_url": "https://api.intrav2.42.fr/v2/achievements/79/users"
				},
				{
					"id": 88,
					"name": "Love me, I'm famous",
					"description": "Avoir été upvoté 1 fois sur le forum.",
					"users_url": "https://api.intrav2.42.fr/v2/achievements/88/users"
				},
				{
					"id": 50,
					"name": "Film buff",
					"description": "Regarder 42 videos sur l'e-learning.",
					"users_url": "https://api.intrav2.42.fr/v2/achievements/50/users"
				},
				{
					"id": 49,
					"name": "Film buff",
					"description": "Regarder 21 videos sur l'e-learning.",
					"users_url": "https://api.intrav2.42.fr/v2/achievements/49/users"
				},
				{
					"id": 78,
					"name": "Perfect examiner",
					"description": "Avoir un feedback correcteur à 100% sur 3 soutenances d'affilée.",
					"users_url": "https://api.intrav2.42.fr/v2/achievements/78/users"
				},
				{
					"id": 46,
					"name": "Film buff",
					"description": "Regarder 1 video sur l'e-learning.",
					"users_url": "https://api.intrav2.42.fr/v2/achievements/46/users"
				}
			],
			"titles": [

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
