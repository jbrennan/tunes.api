# this class is no-frills hack to support nicer phpmarkdown extra features in ruby.
class RedMarkdown
  def initialize(text)
	@text = text
  end
  def to_html
	open("|php markdown.php", 'r+') do |io|
	  io.write(@text)
	  io.close_write
	  io.read
	end
  end
end