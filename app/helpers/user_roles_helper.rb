module UserRolesHelper
  def role_icon_svg_tag(role, blank, title, classes = [])
    path_data = "M 10,2 8.125,8 2,8 6.96875,11.71875 5,18 10,14 15,18 13.03125,11.71875 18,8 11.875,8 10,2 z"
    tag.svg(:width => 20, :height => 20, :class => ["role-icon", role, *classes]) do
      concat tag.title(title)
      concat tag.path(:d => path_data,
                      :fill => blank ? "none" : "currentColor",
                      :stroke => "currentColor",
                      "stroke-width" => blank ? 1.5 : 2,
                      "stroke-linejoin" => "round")
    end
  end
end
