class Admin::MembershipsController < Admin::BaseController
  inherit_resources
  belongs_to :project
end
