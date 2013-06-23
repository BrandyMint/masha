class UserDecorator < ApplicationDecorator
  delegate_all

  def avatar_url
    authentications.each do |a|
      image = a.auth_hash['info']['image']

      return image if image.present?
    end

    return 'http://placehold.it/24x24'
  end

  def avatar
    helpers.image_tag avatar_url
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
