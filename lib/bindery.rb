require 'bundler/setup'
require 'nokogiri'

class Bindery
	def initialize(source,destination)
		html_doc = ''
		File.open(source) do |file|
			html_doc = Nokogiri::XML(file,&:noblanks)
		end
		
		update_style_tag(html_doc)
		format_chapter_breaks(html_doc)
		format_scene_breaks(html_doc)
		remove_empty_paragraphs(html_doc)
		html_text = html_doc.to_xhtml indent:4
		html_text = fix_em_dashes html_text
		html_text = fix_ellipses html_text
		html_text = fix_quotes html_text
		
		File.open(destination,'w') do |file|
			file.puts html_text
		end
	end
	def fix_em_dashes(input)
		input.gsub '--','&mdash;'
	end
	def fix_ellipses(input)
		input.gsub '...','&hellip;'
	end
	def fix_quotes(input)
		input = replace_quotes(input)
		input = ' '+input+' '
		last_is_left = true
		is_first = true
		last_is_single = nil
		processor_on = true
		input.gsub(/['"<>]/) do |char|
			offset = Regexp.last_match.offset(0).first
			next char if contraction? char,input,offset
			if %w{< >}.include?(char)
				processor_on = processor_on? char
				next char
			end
			next char unless processor_on
			
			current_is_single = current_is_single?(char)
			current_is_left = current_is_left?(char,last_is_single,last_is_left)
			char = find_entity char,current_is_left
			last_is_left = current_is_left
			last_is_single = current_is_single
			char
		end.strip
	end
	def update_style_tag(document)
		style = document.css('style').first
		style.content = style_content
	end
	def replace_quotes(input)
		input.gsub('&quot;','"')
	end
	def format_chapter_breaks(document)
		paragraphs = document.css('p')
		paragraphs.each do |p|
			chapter_break_found = true
			q=p
			next if !page_break_before?(q) && q!=paragraphs.first
			14.times do
				chapter_break_found = false if !paragraph_empty? q
				if q.next_sibling == nil
					chapter_break_found = false
					next
				end
				q = q.next_sibling
			end
			next unless chapter_break_found
			q['class']='chapter'
			q.next_sibling['class']='headline'
			q.next_sibling.add_next_sibling(Nokogiri::XML::Node.new "br",document)
		end
	end
	def format_scene_breaks(document)
		paragraphs = document.css('p')
		paragraphs.each do |p|
			if p.content=='#'
				p.content=''
				p['class'] = 'centered'
				img = Nokogiri::XML::Node.new "img",document
				img['src']='vignette.png'
				img['alt']='vignette'
				p.add_child(img)
			end
		end
	end
	def remove_empty_paragraphs(document)
		paragraphs = document.css('p')
		paragraphs.each do |p|
			p.remove if paragraph_empty? p
		end
	end
	private
	def contraction?(char,input,offset)
		return false if offset==0
		input[offset-1].match(/\w/) && input[offset+1].match(/\w/) && %w{' "}.include?(char)
	end
	def processor_on?(char)
		return false if char=='<'
		true
	end
	def current_is_single?(char)
		return true if char=="'"
		false
	end
	def current_is_left?(char,last_is_single,last_is_left)
		return !last_is_left if current_is_single?(char)==last_is_single
		return last_is_left
	end
	def find_entity(char,current_is_left)
		if current_is_single? char
			return '&lsquo;' if current_is_left
			'&rsquo;'		
		else
			return '&ldquo;' if current_is_left
			'&rdquo;'
		end			
	end
	def style_content
		'
			html, body, div, h1, h2, h3, h4, h5, h6, ul, ol, dl, li, dt, dd, p, blockquote, pre, form, fieldset, table, th, td, tr { margin: 0; padding: 0.1em; }

			p
			{
			text-indent: 1.5em;
			margin-bottom: 0.2em;
			}

			p.title
			{
			font-size: 1.5em;
			font-weight: bold;
			margin-top: 5em;
			}

			p.headline
			{
			text-indent: 1.5em;
			font-weight: bold;
			margin-top: 1.5em;
			}

			p.chapter
			{
			font-size:2em;
			text-indent: 1.5em;
			page-break-before: always;
			font-weight: bold;
			margin-top:5em;
			margin-bottom:2em;
			}
			
			p.centered
			{
			text-indent: 0em;
			text-align: center;
			}
			span.centered
			{
			text-indent: 0em;
			text-align: center;
			}'
	end
	def paragraph_empty?(p)
		p['style'].start_with?('-qt-paragraph-type:empty;')
	end
	def page_break_before?(p)
		p['style'].end_with?('page-break-before:always;')
	end
end