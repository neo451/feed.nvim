local xml = require("rss.xml")

describe("element", function()
	it("should produce a table of k v pair", function()
		assert.same({ title = "arch by the way" }, xml.parse("<title>arch by the way</title>"))
	end)
end)

describe("nested elements", function()
	it("should produce one table of k v pairs collected from all children", function()
		local src = [[
	<channel>
	<title>arch</title>
	<link>https://archlinux.org/feeds/news/</link>
	</channel>
	]]

		local src2 = [[
	<pre>
	<channel>
			<title>arch</title>
			<link>https://archlinux.org/feeds/news/</link>
	</channel>
	</pre>
	]]
		assert.same({ channel = { title = "arch", link = "https://archlinux.org/feeds/news/" } }, xml.parse(src))
		assert.same(
			{ pre = { channel = { title = "arch", link = "https://archlinux.org/feeds/news/" } } },
			xml.parse(src2)
		)
	end)
	it("should treat text as element", function()
		local src = [[<h1>zig <code>const std = @import("std")</code> by the way</h1>]]
		local expected = { h1 = { "zig ", { code = 'const std = @import("std")' }, "by the way" } }
		assert.same(expected, xml.parse(src))
	end)
end)

describe("attrs", function()
	it("should produce kv pair from start tag attrs", function()
		local src = [[<rss version="2.0"></rss>]]
		assert.same({ rss = { version = "2.0" } }, xml.parse(src))
		-- TODO: not really needed
		-- local src2 = [[<?xml.parse version="1.0" encoding="UTF-8"?>]]
		-- assert.same({ xml = { version = "1.0", encoding = "UTF-8" } }, xml.XMLDecl:match(src2))
	end)
end)

describe("CData", function()
	it("should treat CDate block as text", function()
		local text =
			[[<img src="https://image.gcores.com/0264adbd011a43624c087e3b9a4fea23-2048-1148.jpg?x-oss-process=image/resize,limit_1,m_fill,w_626,h_292/quality,q_90" /><p>为了庆祝《变形金刚》40周年，孩之宝与日本著名动画工作室扳机社（TRIGGER）合作，制作一部40周年特别纪念PV。</p><div>
<figure><p>&lt;内嵌内容，请前往机核查看&gt;</p></figure></div><div>
<figure><img src="https://image.gcores.com/d588b5fb102a3ef20443d6cb3c92a8c6-2048-1148.jpg?x-oss-process=image/resize,limit_1,m_lfit,w_700,h_2000/quality,q_90/watermark,image_d2F0ZXJtYXJrLnBuZw,g_se,x_10,y_10" alt=""></figure></div><div>
<figure><img src="https://image.gcores.com/37023d7bac205fc3e6593a9f50c10852-2048-1148.jpg?x-oss-process=image/resize,limit_1,m_lfit,w_700,h_2000/quality,q_90/watermark,image_d2F0ZXJtYXJrLnBuZw,g_se,x_10,y_10" alt=""></figure></div><div>
<figure><img src="https://image.gcores.com/073b2716852332443dd46b97ec0ae50d-2048-1148.jpg?x-oss-process=image/resize,limit_1,m_lfit,w_700,h_2000/quality,q_90/watermark,image_d2F0ZXJtYXJrLnBuZw,g_se,x_10,y_10" alt=""></figure></div><div>
<figure><img src="https://image.gcores.com/5a3e0d3bfeccc2bb863c9b0bac11009e-2048-1148.jpg?x-oss-process=image/resize,limit_1,m_lfit,w_700,h_2000/quality,q_90/watermark,image_d2F0ZXJtYXJrLnBuZw,g_se,x_10,y_10" alt=""></figure></div><p></p><p></p>]]
		local src = "<description><![CDATA[" .. text .. "]]></description>"
		assert.same({ description = text }, xml.parse(src))
	end)
end)

describe("same name tags", function()
	it("should add parellel same-name tags to a single table", function()
		local src = [[
<rss>
<item>1</item>
<item>2</item>
<item>3</item>
</rss>
		]]
		local expected = {
			rss = {
				item = { "1", "2", "3" },
			},
		}
		assert.same(expected, xml.parse(src))
	end)
end)

describe("acutual rss feed", function()
	it("should produce simple lua table", function()
		local line = vim.fn.readfile("test.xml")
		local str = table.concat(line)
		local ast = xml.parse(str)
		-- print(vim.inspect(ast))
		local description = "不止是游戏"
		local generator = "http://rubyonrails.org/"
		assert.same(description, ast.channel.description)
		assert.same(generator, ast.channel.generator)
	end)
end)

describe("html", function()
	it("should parse html", function()
		local src = [[
<h1>hello world</h1>
<p>this is so coollll</p>
		]]
		assert.same({ { h1 = "hello world" }, { p = "this is so coollll" } }, xml.parse(src))
	end)
end)
