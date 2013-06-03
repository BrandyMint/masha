class UserDecorator < ApplicationDecorator
  delegate_all

  def available_projects
    arbre :user => source do
      ul :class => 'horizontal-list' do
        user.projects.each do |p|
          li do
            helpers.link_to p, helpers.project_url(p)
          end
        end
      end
    end
  end

end
