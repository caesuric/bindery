require 'spec_helper'
require 'bindery'

describe Bindery do
	subject {described_class.new 'spec/template/input.html','zxcv'}
	context '.fix_em_dashes' do
		it 'does nothing when there aren\'t any' do
			expect(subject.fix_em_dashes('asdf')).to eq 'asdf'
		end
		it 'replaces all double-dashes with the escape code for em-dashes' do
			expect(subject.fix_em_dashes('--stuff--')).to eq '&mdash;stuff&mdash;'
		end
	end
	context '.fix_ellipses' do
		it 'does nothing when there aren\'t any' do
			expect(subject.fix_ellipses('asdf')).to eq 'asdf'
		end
		it 'replaces all cases of ... with the escape code for ellipses' do
			expect(subject.fix_ellipses('...stuff...')).to eq '&hellip;stuff&hellip;'
		end
	end
	context '.initialize' do
		it 'fixes em-dashes' do
			expect_any_instance_of(Bindery).to receive(:fix_em_dashes).and_return 'asdf'
			Bindery.new('spec/template/input.html','zxcv')
		end
		it 'fixes ellipses' do
			expect_any_instance_of(Bindery).to receive(:fix_ellipses).and_return 'asdf'
			Bindery.new('spec/template/input.html','zxcv')
		end
	end
	context '.fix_quotes' do
		it 'fixes a single pair of single quotes' do
			expect(subject.fix_quotes("'abc'")).to eq '&lsquo;abc&rsquo;'
		end
		it 'fixes a single pair of double quotes' do
			expect(subject.fix_quotes('"abc"')).to eq '&ldquo;abc&rdquo;'
		end
		it 'fixes a single pair of single quotes within a single pair of double quotes' do
			expect(subject.fix_quotes(%q{"'abc'"})).to eq '&ldquo;&lsquo;abc&rsquo;&rdquo;'
		end
		it 'fixes a single pair of double quotes within a single pair of single quotes' do
			expect(subject.fix_quotes(%q{'"abc"'})).to eq '&lsquo;&ldquo;abc&rdquo;&rsquo;'
		end
		it 'fixes complicated sets of nested quotes' do
			expect(subject.fix_quotes(%q{'"'"'abc'"'"'})).to eq '&lsquo;&ldquo;&lsquo;&ldquo;&lsquo;abc&rsquo;&rdquo;&rsquo;&rdquo;&rsquo;'
		end
		it 'fixes multiple sets of nested quotes' do
			expect(subject.fix_quotes(%q{'"'"'abc'"'"' '"'"'abc'"'"'})).to eq '&lsquo;&ldquo;&lsquo;&ldquo;&lsquo;abc&rsquo;&rdquo;&rsquo;&rdquo;&rsquo; &lsquo;&ldquo;&lsquo;&ldquo;&lsquo;abc&rsquo;&rdquo;&rsquo;&rdquo;&rsquo;'
		end
		it 'ignores content within angular brackets' do
			expect(subject.fix_quotes(%q{<''"""''">''})).to eq %q{<''"""''">&lsquo;&rsquo;}
		end
		it 'ignores single quotes in the middle of words' do
			expect(subject.fix_quotes(%q{'don't'})).to eq "&lsquo;don't&rsquo;"
		end
		it 'processes lines containing &xxquo; entities' do
			input = %q{<p style=" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:36px;">&quot;That's unjust, Demeter. Or, should I call you <span style=" text-decoration: underline;">mother </span>now?&quot; </p>}
			output = %q{<p style=" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:36px;">&ldquo;That's unjust, Demeter. Or, should I call you <span style=" text-decoration: underline;">mother </span>now?&rdquo; </p>}
			expect(subject.fix_quotes(input)).to eq output
		end
		it 'processes pre-existing &quot; entities correctly' do
			expect(subject.fix_quotes('&quot;&quot;')).to eq '&ldquo;&rdquo;'
		end
		it 'processes quotes across nested tags' do
			expect(subject.fix_quotes('<p>"This <b>is</b> a quote"</p>')).to eq '<p>&ldquo;This <b>is</b> a quote&rdquo;</p>'
		end
	end
	context '.update_style_tag' do
		before :each do
			@doc = Nokogiri::HTML::Builder.new do |doc|
				doc.html do
					doc.style 'old style'
					doc.body 'text'
				end
			end.doc
		end
		it 'replaces the contents of the style tag with defined text' do
			expect(subject).to receive(:style_content).and_return 'my custom style'
			subject.update_style_tag(@doc)
			expect(@doc.css('style').first.content).to eq 'my custom style'
		end
	end
end