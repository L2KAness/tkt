fx_version('bodacious')
game('gta5')

author('L2KAnes')
version('2.0')

dependency('mFramework')

server_scripts({
	'@mysql-async/lib/MySQL.lua',
	'@mFramework/locale.lua',
	'locales/*.lua',
	'config.lua',
	'server/main.lua'
})

--client_script('@korioz/lib.lua')
client_scripts({
	'dependencies/RMenu.lua',
	'dependencies/menu/RageUI.lua',
	'dependencies/menu/Menu.lua',
	'dependencies/menu/MenuController.lua',
	'dependencies/components/*.lua',
	'dependencies/menu/elements/*.lua',
	'dependencies/menu/items/*.lua',

	'@mFramework/locale.lua',
	'locales/*.lua',
	'config.lua',
	'client/main.lua',
	'client/other.lua'
})

ui_page('html/ui.html')

files({
	'html/ui.html',
	'html/css/app.css',
	'html/js/app.js',
	'html/img/*.png'
})