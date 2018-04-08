require_dependency 'custom_redmine_links/repository_patch'
require_dependency 'custom_redmine_links/repositories_helper_patch'
require_dependency 'custom_redmine_links/changeset_patch.rb'

ActionDispatch::Callbacks.to_prepare do
  require_dependency 'application_helper'
  require_dependency 'custom_redmine_links/application_helper_patch'
end

Redmine::Plugin.register :custom_redmine_links do
  name 'Custom Redmine Links'
  author 'Remizov Nikita'
  description 'Customization of Redmine repository links.'
  version '0.0.2'
end