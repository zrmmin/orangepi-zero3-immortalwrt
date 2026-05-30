'use strict';
'require view';
'require form';
'require uci';

return view.extend({
	load: function() {
		return uci.load('zero3ap');
	},
	render: function() {
		var m, s, o;
		m = new form.Map('zero3ap', _('板载 AP (WiFi)'),
			_('管理板载 UWE5622 无线热点(独立 hostapd,绕开 netifd,稳定可靠)。保存并应用后会自动重启 AP。'));

		s = m.section(form.NamedSection, 'config', 'zero3ap', _('热点设置'));
		s.anonymous = true;

		o = s.option(form.Flag, 'enabled', _('启用 AP'));
		o.default = '1';
		o.rmempty = false;

		o = s.option(form.Value, 'ssid', _('网络名称 (SSID)'));
		o.datatype = 'maxlength(32)';
		o.rmempty = false;

		o = s.option(form.ListValue, 'encryption', _('加密方式'));
		o.value('psk2', 'WPA2-PSK');
		o.value('none', _('无加密(开放网络)'));
		o.default = 'psk2';

		o = s.option(form.Value, 'key', _('Wi-Fi 密码'));
		o.password = true;
		o.datatype = 'wpakey';
		o.depends('encryption', 'psk2');

		o = s.option(form.ListValue, 'channel', _('信道 (2.4GHz)'));
		for (var i = 1; i <= 13; i++) o.value(String(i), String(i));
		o.default = '6';

		o = s.option(form.Flag, 'hidden', _('隐藏 SSID'));
		o.default = '0';

		o = s.option(form.Value, 'country', _('国家代码'));
		o.datatype = 'maxlength(2)';
		o.default = 'CN';

		return m.render();
	}
});
