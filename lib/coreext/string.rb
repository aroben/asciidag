class String
  def substring_after(index)
    slice(index, length - index)
  end
end
