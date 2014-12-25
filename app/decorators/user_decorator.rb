class UserDecorator < ApplicationDecorator
  delegate_all

  def name
    email = source.email.present? ? source.email : 'no email'
    "#{source.name} <span class='text-muted'>(#{email})</span>".html_safe
  end

  def name_as_link
    remote_url = self.remote_profile_url
    if remote_url.present?
      h.link_to self.name, remote_url
    else
      self.name
    end
  end

  def link
    h.link_to source.name, h.user_url(source)
  end

  def remote_profile_url
    url = nil
    authentications.each do |a|
      extra = a.auth_hash['extra']
      url = extra['raw_info']['html_url'] if extra['raw_info'].present?
    end
    url
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
    arbre user: source do
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
