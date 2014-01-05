{% extends "admin_edit_widget_std.tpl" %}

{# Show the edit fields to edit the name of a person #}

{% block widget_title %}{_ Address _}{% endblock %}
{% block widget_show_minimized %}true{% endblock %}
{% block widget_id %}content-address{% endblock %}

{% block widget_content %}
{% with m.rsc[id] as r %}
	<div class="form-group">
		<label class="col-sm-3 control-label" for="phone">{_ Telephone _}</label>
		<div class="col-sm-3">
		<input id="phone" type="text" name="phone" value="{{ r.phone }}" class="form-control" />
		</div>

		<label class="col-sm-3 control-label" for="phone_alt">{_ Alternative telephone _}</label>
		<div class="col-sm-3">
		<input id="phone_alt" type="text" name="phone_alt" value="{{ r.phone_alt }}" class="form-control" />
		</div>
	</div>

	<div class="form-group">
		<label class="col-sm-3 control-label" for="phone">{_ Mobile _}</label>
		<div class="col-sm-3">
		<input id="phone_mobile" type="text" name="phone_mobile" value="{{ r.phone_mobile }}" class="form-control" />
		</div>

		<label class="col-sm-3 control-label" for="phone_emergency">{_ Emergency telephone _}</label>
		<div class="col-sm-3">
		<input id="phone_emergency" type="text" name="phone_emergency" value="{{ r.phone_emergency }}" class="form-control" />
		</div>
	</div>

	<div class="form-group">
		<label class="col-sm-3 control-label" for="website">{_ Website _}</label>
		<div class="col-sm-9">
			<input id="website" type="url" name="website" value="{{ r.website }}" class="form-control" />
		</div>
	</div>

        {% catinclude "_admin_edit_content_address_email.tpl" r.id %}

	<h5>{_ Visiting address _}</h5>

	<div class="form-group">
		<label class="col-sm-3 control-label" for="address_country">{_ Country _}</label>
		<div class="col-sm-6">
		{% if m.modules.info.mod_l10n.enabled %}
			<select id="address_country" name="address_country" class="form-control">
				<option value=""></option>
				{% optional include "_l10n_country_options.tpl" country=r.address_country %}
			</select>
		{% else %}
			<input id="address_country" type="text" name="address_country" value="{{ r.address_country }}" class="form-control" />
		{% endif %}
		</div>
	</div>
	{% wire id="address_country" 
			type="change" 
			action={script script="
				if ($(this).val() != '') $('#visit_address').slideDown();
				else $('#visit_address').slideUp();
			"}
	%}

	<div id="visit_address" {% if not r.address_country %}style="display:none"{% endif %}>
		<div class="form-group">
			<label class="col-sm-3 control-label" for="address_street_1">{_ Street Line 1 _}</label>
			<div class="col-sm-9">
				<input id="address_street_1" type="text" name="address_street_1" value="{{ r.address_street_1 }}" class="form-control" />
			</div>
		</div>

		<div class="form-group">
			<label class="col-sm-3 control-label" for="address_street_2">{_ Street Line 2 _}</label>
			<div class="col-sm-9">
				<input id="address_street_2" type="text" name="address_street_2" value="{{ r.address_street_2 }}" class="form-control" />
			</div>
		</div>

		<div class="form-group">
			<label class="col-sm-3 control-label" for="address_city">{_ City _}</label>
			<div class="col-sm-3">
				<input id="address_city" type="text" name="address_city" value="{{ r.address_city }}" class="form-control" />
			</div>

			<label class="col-sm-3 control-label" for="address_postcode">{_ Postcode _}</label>
			<div class="col-sm-3">
				<input id="address_postcode" type="text" name="address_postcode" value="{{ r.address_postcode }}" class="form-control" />
			</div>
		</div>

		<div class="form-group">
			<label class="col-sm-3 control-label" for="address_state">{_ State _}</label>
			<div class="col-sm-3">
				<input id="address_state" type="text" name="address_state" value="{{ r.address_state }}" class="form-control" />
			</div>
		</div>
	</div>

	<h5>{_ Mailing address _}</h5>

	<div class="form-group">
		<label class="col-sm-3 control-label" for="mail_country">{_ Country _}</label>
		<div class="col-sm-6">
		{% if m.modules.info.mod_l10n.enabled %}
			<select id="mail_country" name="mail_country" class="form-control">
				<option value=""></option>
				{% optional include "_l10n_country_options.tpl" country=r.mail_country %}
			</select>
		{% else %}
			<input id="mail_country" type="text" name="mail_country" value="{{ r.mail_country }}" class="form-control" />
		{% endif %}
		</div>
	</div>
	{% wire id="mail_country" 
			type="change" 
			action={script script="
				if ($(this).val() != '') $('#mail_address').slideDown();
				else $('#mail_address').slideUp();
			"}
	%}

	<div id="mail_address" {% if not r.mail_country %}style="display:none"{% endif %}>
		<div class="form-group">
			<label class="col-sm-3 control-label" for="mail_street_1">{_ Street Line 1 _}</label>
			<div class="col-sm-9">
				<input id="mail_street_1" type="text" name="mail_street_1" value="{{ r.mail_street_1 }}" class="form-control" />
			</div>
		</div>

		<div class="form-group">
			<label class="col-sm-3 control-label" for="mail_street_2">{_ Street Line 2 _}</label>
			<div class="col-sm-9">
				<input id="mail_street_2" type="text" name="mail_street_2" value="{{ r.mail_street_2 }}" class="form-control" />
			</div>
		</div>

		<div class="form-group">
			<label class="col-sm-3 control-label" for="mail_city">{_ City _}</label>
			<div class="col-sm-3">
				<input id="mail_city" type="text" name="mail_city" value="{{ r.mail_city }}" class="form-control" />
			</div>

			<label class="col-sm-3 control-label" for="mail_postcode">{_ Postcode _}</label>
			<div class="col-sm-3">
				<input id="mail_postcode" type="text" name="mail_postcode" value="{{ r.mail_postcode }}" class="form-control" />
			</div>
		</div>

		<div class="form-group">
			<label class="col-sm-3 control-label" for="mail_state">{_ State _}</label>
			<div class="col-sm-3">
				<input id="mail_state" type="text" name="mail_state" value="{{ r.mail_state }}" class="form-control" />
			</div>
		</div>
	</div>

{% endwith %}
{% endblock %}
