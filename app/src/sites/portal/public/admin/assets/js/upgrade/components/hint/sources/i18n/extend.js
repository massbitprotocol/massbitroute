export default function extend(lang, data){
	var obj = webix.i18n.locales[lang];
	if (obj)
		webix.extend(obj, data);
}