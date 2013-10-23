class UserDecorator < ApplicationDecorator
  delegate_all

  def name
    "#{source.name} <span class='text-muted'>(#{source.email})</span>".html_safe
  end

  def avatar_url
    authentications.each do |a|
      image = a.auth_hash['info']['image']

      return image if image.present?
    end

    return 'http://placehold.it/80x80'
  end

  def avatar
    helpers.image_tag avatar_url, :size => '80x80'
  end

  def available_projects
    arbre :user => source do
      ul :class => 'horizontal-list' do
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
