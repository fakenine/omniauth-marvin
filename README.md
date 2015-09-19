# Omniauth Marvin

OmniAuth OAuth2 strategy for 42 School.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'omniauth-marvin', github: "fakenine/omniauth-marvin"
```

run `bundle install`

## Usage

Register your application on 42's intranet to receive an API Key.

Here's an example for adding the middleware to a Rails app in `config/initializers/omniauth.rb`

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :marvin, ENV["42_ID"], ENV["42_SECRET"]
end
```

You can now access the OmniAuth 42 OAuth2 URL: `/auth/marvin`

## Devise

If you wish to use this gem with devise, do not use the code snippet above in the Usage section. Instead, follow these steps:

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
  config.omniauth :marvin, ENV["42_ID"], ENV["42_SECRET"]
  .
  .
end
```

Don't forget to set the "42_ID" and "42_SECRET" (your app id and secret) in your environment variables.


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
      # If your user model has other attributes for which you can get the values via the
      # 42 API, add them here. For instance:
      # user.level = auth.info.level
      # user.image = auth.info.image
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

An example of auth hash will be added when the API goes public.

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
