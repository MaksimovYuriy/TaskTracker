Tag::SYSTEM_TITLES.each do |title|
  Tag.find_or_create_by!(title: title)
end
