class Owner::MembershipsController < Owner::BaseController
  inherit_resources
  belongs_to :project
end
