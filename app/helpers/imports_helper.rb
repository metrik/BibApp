module ImportsHelper

  def imported_for(import)
    if import.person_id
      if person = Person.find_by_id(import.person_id)
        return link_to(person.display_name, person_path(person))
      else
        return 'Deleted Person'
      end
    else
      return "System"
    end
  end

  def import_name_string_line(name, person)
    classes = name[1][:works].collect { |w| "work-#{w}" }.join(" ")
    capture_haml do
      haml_tag :li, {:id => "ns-#{name[1][:id]}", :class => "#{classes}", :style => "border-bottom:1px solid #CCC; list-style:none; line-height:1.75em;"} do
        haml_tag :span, ajax_pen_name_checkbox_toggle(NameString.find_by_id(name[1][:id]), person, false, true)
        haml_tag :span, "#{name[0]} (#{name[1][:works].size})", {:class => "name_string span-5 prepend-1"}
        haml_tag :span, "#{name[1][:works].size}", {:id => "ns-#{name[1][:id]}-count", :class=> "hide"}
      end
    end
  end

  def body_header(person)
    ('Add Works' + (person ? " for #{link_to person.display_name, person_path(person)}" : '')).html_safe
  end

end
