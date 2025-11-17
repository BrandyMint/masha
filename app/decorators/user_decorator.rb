# frozen_string_literal: true

class UserDecorator < ApplicationDecorator
  delegate_all

  def name
    email = object.email.presence || 'no email'
    h.safe_join([
      h.content_tag(:span, object.name),
      ' ',
      h.content_tag(:span, "(#{email})", class: 'text-muted')
    ])
  end

  def name_as_link
    remote_url = remote_profile_url
    if remote_url.present?
      h.link_to name, remote_url
    else
      name
    end
  end

  def link
    h.link_to object.name, h.user_url(object)
  end

  def remote_profile_url
    authentications.map do |a|
      (a.auth_hash['extra'] || {})
        .fetch('raw_info', {})
        .fetch('html_url', '')
    end.first
  end

  def avatar_url
    authentications.each do |a|
      image = a.auth_hash['info']['image']

      return image if image.present?
    end

    'http://placehold.it/80x80'
  end

  def avatar
    helpers.image_tag avatar_url, size: '80x80'
  end

  def available_projects
    arbre user: object do
      ul class: 'horizontal-list' do
        user.projects.each do |p|
          li do
            helpers.link_to helpers.project_url(p) do
              helpers.role_label user.membership_of(p), true, p.to_s
            end
          end
        end
      end
    end
  end
end
