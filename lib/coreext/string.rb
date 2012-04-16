class String
  def index_of_earliest_match_ending_at(regexp, end_index)
    (0..end_index).each do |index|
      match = slice(index..end_index).match regexp
      next if match.nil? || index + match[0].length != end_index + 1
      return index
    end
    nil
  end

  def substring_after(index)
    slice(index, length - index)
  end
end
