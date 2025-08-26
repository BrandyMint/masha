# frozen_string_literal: true

module Owner
  class MembershipsController < Owner::BaseController
    inherit_resources
    belongs_to :project
  end
end
