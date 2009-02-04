require 'find'

# initial settings
ALLOWED_EXTENSIONS = "py;html;rb;yml;sql;c;php;js;rhtml;erb;rake"
ALLOWED_FILES = "README"
SKIPPED_DIRECTORIES = "vendor;temp;.svn;CVS;_darcs"
SKIPPED_FILES = ""
MARKS_REGEX = /\b(TODO|FIXME|CHANGED|NOTE|OPTIMIZE|IMPROVE)\b:? +(.*?)$/

def file_link(file, line = 0)
  "gedit://#{file}?line=#{line-1}"
end

def escape(str)
  str.gsub(/</sm, "&lt;").gsub(/>/sm, "&gt;")
end

root = ARGV[0]
matches = {}
allowed_extensions = ALLOWED_EXTENSIONS.split(";")
allowed_files = ALLOWED_FILES.split(";")
skipped_directories = SKIPPED_DIRECTORIES.split(";")
skipped_files = SKIPPED_FILES.split(";")

Find.find(root) do |path|
  basename = File.basename(path)
  match, ext = *basename.match(/\.(.*?)$/)
  
  ext.to_s.downcase!
  
  if FileTest.directory?(path) && skipped_directories.include?(basename)
    Find.prune
  elsif FileTest.file?(path) && (allowed_extensions.include?(ext) || allowed_files.include?(basename)) && !skipped_files.include?(basename)
    File.open(path) do |io|
      io.grep(MARKS_REGEX) do |match|
        # convert label to symbol
        sym = $1.downcase.to_sym
        
        # if hasn't been set yet
        matches[sym] = [] unless matches[sym]
        
        matches[sym] << {
          :path => path,
          :file => basename,
          :line_number => io.lineno.to_i,
          :text => $2
        }
      end
    end
  end
end

html = ''
menu = '<ul id="navigation">'
total = 0

matches.keys.each do |label|
  total += matches[label].size
  menu << '<li class="%s"><a href="#%s-title">%s</a>: %d</li>' % [label, label, label.to_s.upcase, matches[label].size]
  html << "<h2 id=\"#{label}-title\">#{label.to_s.upcase}</h2>"
  html << '<table id="%s">' % label
  html << '
    <thead>
      <tr>
        <th class="file">File</th>
        <th class="comment">Comment</th>
      </tr>
    </thead>
    <tbody>
  '
  
  matches[label].each_with_index do |item,i|
    css = i % 2 == 0 ? 'even' : 'odd'
    html << '<tr class="%s"><td><a href="%s">%s</a> <span>(%s)</span></td><td>%s</td>' % [css, file_link(item[:path], item[:line_number]), item[:file], item[:line_number], escape(item[:text])]
  end
  
  html << "</tbody></table>"
end

menu << '<li class="total">Total: %s</li></ul>' % total
html << '<a href="#todo_list" id="toplink">↑ top</a>'
html << '</div>'
html = ('<div id="todo_list">%s' % menu) << html

markup = <<HTML
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
	"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html>
<head>
	<meta http-equiv="Content-type" content="text/html; charset=utf-8" />
	<title>ToDo List</title>
	<style type="text/css">
	  * {
	    color: #333;
	  }
	  
	  body {
    	font-size: 12px;
    	font-family: "bitstream vera sans mono", "sans-serif";
    	padding: 0;
    	margin: 0;
    	
    	width: 700px;
    	height: 500px;
    }

    th {
    	text-align: left;
    }

    td {
    	vertical-align: top;
    }
    
    #fixme-title {
    	color: #a00
    }
    
    #todo-title {
    	color: #CF830D
    }
    
    #changed-title {
    	color: #008000;
    }
    
    #note-title {
      color: #1E90FF;
    }
    
    #optimize-title {
      color: #a020f0;
    }
    
    #improve-title {
      color: #d618a4;
    }
    
    th, a {
    	color: #0D2681
    }
    
    .odd td {
    	background: #f0f0f0
    }
    
    table {
    	border-collapse: collapse;
    	width: 650px;
    }
    
    td,th {
    	padding: 3px;
    }
    
    th {
    	border-bottom: 1px solid #999;
    }
    
    th.file {
    	width: 30%;
    }
    
    #toplink {
    	position: fixed;
    	bottom: 10px;
    	right: 40px;
    }
    
    h1 {
    	background: #6A0071;
    	color: #ccc;
    	padding: 20px 5px 5px 5px;
    	margin: 0;
    }
    
    h2 {
    	font-size: 16px;
    	margin: 0 0 10px;
    	padding-top: 30px;
    }
    
    #page {
    	overflow: auto;
    	height: 406px;
    	padding: 0 15px 20px 15px;
    	position: relative;
    }
    
    #root {
    	position: absolute;
    	top: 15px;
    	right: 10px;
    	color: #fff;
    }
    
    #navigation {
    	margin: 0;
    	padding: 0;
    	border-left: 1px solid #000
    }
    
    #navigation * {
    	color: #fff;
    }
    
    li.todo {
    	background: #CF830D
    }
    
    li.fixme {
    	background: #a00;
    	border-width: 1px 0;
    }
    
    li.changed {
    	background: #008000
    }
    
    li.total {
    	background: #000000
    }
    
    li.note {
      background: #1E90FF
    }
    
    li.optimize {
      background: #a020f0;
    }
    
    li.improve {
      background: #d618a4;
    }
    
    #navigation li {
    	float: left;
    	list-style: none;
    	text-align: center;
    	padding: 7px 10px;
    	margin: 0;
    	border: 1px solid #000;
    	border-left: none;
    }
    
    #navigation:after {
	    content: "."; 
	    display: block; 
	    height: 0; 
	    clear: both; 
	    visibility: hidden;
	}
	
	#todo_list {
		padding-top: 30px;
	}
	
	#container {
		position: relative;
	}
	</style>
</head>
<body>
<div id="container">
<h1>ToDo List</h1>
<p id="root">#{escape(root)}</p>
<div id="page">
	#{html}
</div>
</div>
</body>
</html>
HTML

tmp_file = "/tmp/todo.html"

File.unlink(tmp_file) if File.exists?(tmp_file)
File.new(tmp_file, 'w+').puts markup
