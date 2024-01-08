struct Options
  property win_size : Int32
  property threshold : Int32
  property in_file : Path?

  def initialize(@in_file = nil, @win_size = 64, @threshold = 20)
  end
end
