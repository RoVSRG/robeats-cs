local Countries = {}

local countryList = {
	BD = {Name = "Bangladesh", Flag = "🇧🇩"},
	BE = {Name = "Belgium", Flag = "🇧🇪"},
	BF = {Name = "Burkina Faso", Flag = "🇧🇫"},
	BG = {Name = "Bulgaria", Flag = "🇧🇬"},
	BA = {Name = "Bosnia and Herzegovina", Flag = "🇧🇦"},
	BB = {Name = "Barbados", Flag = "🇧🇧"},
	WF = {Name = "Wallis and Futuna", Flag = "🇼🇫"},
	BL = {Name = "Saint Barthelemy", Flag = "🇧🇱"},
	BM = {Name = "Bermuda", Flag = "🇧🇲"},
	BN = {Name = "Brunei", Flag = "🇧🇳"},
	BO = {Name = "Bolivia", Flag = "🇧🇴"},
	BH = {Name = "Bahrain", Flag = "🇧🇭"},
	BI = {Name = "Burundi", Flag = "🇧🇮"},
	BJ = {Name = "Benin", Flag = "🇧🇯"},
	BT = {Name = "Bhutan", Flag = "🇧🇹"},
	JM = {Name = "Jamaica", Flag = "🇯🇲"},
	BV = {Name = "Bouvet Island", Flag = "🇧🇻"},
	BW = {Name = "Botswana", Flag = "🇧🇼"},
	WS = {Name = "Samoa", Flag = "🇼🇸"},
	BQ = {Name = "Bonaire, Saint Eustatius and Saba", Flag = "🇧🇶"},
	BR = {Name = "Brazil", Flag = "🇧🇷"},
	BS = {Name = "Bahamas", Flag = "🇧🇸"},
	JE = {Name = "Jersey", Flag = "🇯🇪"},
	BY = {Name = "Belarus", Flag = "🇧🇾"},
	BZ = {Name = "Belize", Flag = "🇧🇿"},
	RU = {Name = "Russia", Flag = "🇷🇺"},
	RW = {Name = "Rwanda", Flag = "🇷🇼"},
	RS = {Name = "Serbia", Flag = "🇷🇸"},
	TL = {Name = "East Timor", Flag = "🇹🇱"},
	RE = {Name = "Reunion", Flag = "🇷🇪"},
	TM = {Name = "Turkmenistan", Flag = "🇹🇲"},
	TJ = {Name = "Tajikistan", Flag = "🇹🇯"},
	RO = {Name = "Romania", Flag = "🇷🇴"},
	TK = {Name = "Tokelau", Flag = "🇹🇰"},
	GW = {Name = "Guinea-Bissau", Flag = "🇬🇼"},
	GU = {Name = "Guam", Flag = "🇬🇺"},
	GT = {Name = "Guatemala", Flag = "🇬🇹"},
	GS = {Name = "South Georgia and the South Sandwich Islands", Flag = "🇬🇸"},
	GR = {Name = "Greece", Flag = "🇬🇷"},
	GQ = {Name = "Equatorial Guinea", Flag = "🇬🇶"},
	GP = {Name = "Guadeloupe", Flag = "🇬🇵"},
	JP = {Name = "Japan", Flag = "🇯🇵"},
	GY = {Name = "Guyana", Flag = "🇬🇾"},
	GG = {Name = "Guernsey", Flag = "🇬🇬"},
	GF = {Name = "French Guiana", Flag = "🇬🇫"},
	GE = {Name = "Georgia", Flag = "🇬🇪"},
	GD = {Name = "Grenada", Flag = "🇬🇩"},
	GB = {Name = "United Kingdom", Flag = "🇬🇧"},
	GA = {Name = "Gabon", Flag = "🇬🇦"},
	SV = {Name = "El Salvador", Flag = "🇸🇻"},
	GN = {Name = "Guinea", Flag = "🇬🇳"},
	GM = {Name = "Gambia", Flag = "🇬🇲"},
	GL = {Name = "Greenland", Flag = "🇬🇱"},
	GI = {Name = "Gibraltar", Flag = "🇬🇮"},
	GH = {Name = "Ghana", Flag = "🇬🇭"},
	OM = {Name = "Oman", Flag = "🇴🇲"},
	TN = {Name = "Tunisia", Flag = "🇹🇳"},
	JO = {Name = "Jordan", Flag = "🇯🇴"},
	HR = {Name = "Croatia", Flag = "🇭🇷"},
	HT = {Name = "Haiti", Flag = "🇭🇹"},
	HU = {Name = "Hungary", Flag = "🇭🇺"},
	HK = {Name = "Hong Kong", Flag = "🇭🇰"},
	HN = {Name = "Honduras", Flag = "🇭🇳"},
	HM = {Name = "Heard Island and McDonald Islands", Flag = "🇭🇲"},
	VE = {Name = "Venezuela", Flag = "🇻🇪"},
	PR = {Name = "Puerto Rico", Flag = "🇵🇷"},
	PS = {Name = "Palestinian Territory", Flag = "🇵🇸"},
	PW = {Name = "Palau", Flag = "🇵🇼"},
	PT = {Name = "Portugal", Flag = "🇵🇹"},
	SJ = {Name = "Svalbard and Jan Mayen", Flag = "🇸🇯"},
	PY = {Name = "Paraguay", Flag = "🇵🇾"},
	IQ = {Name = "Iraq", Flag = "🇮🇶"},
	PA = {Name = "Panama", Flag = "🇵🇦"},
	PF = {Name = "French Polynesia", Flag = "🇵🇫"},
	PG = {Name = "Papua New Guinea", Flag = "🇵🇬"},
	PE = {Name = "Peru", Flag = "🇵🇪"},
	PK = {Name = "Pakistan", Flag = "🇵🇰"},
	PH = {Name = "Philippines", Flag = "🇵🇭"},
	PN = {Name = "Pitcairn", Flag = "🇵🇳"},
	PL = {Name = "Poland", Flag = "🇵🇱"},
	PM = {Name = "Saint Pierre and Miquelon", Flag = "🇵🇲"},
	ZM = {Name = "Zambia", Flag = "🇿🇲"},
	EH = {Name = "Western Sahara", Flag = "🇪🇭"},
	EE = {Name = "Estonia", Flag = "🇪🇪"},
	EG = {Name = "Egypt", Flag = "🇪🇬"},
	ZA = {Name = "South Africa", Flag = "🇿🇦"},
	EC = {Name = "Ecuador", Flag = "🇪🇨"},
	IT = {Name = "Italy", Flag = "🇮🇹"},
	VN = {Name = "Vietnam", Flag = "🇻🇳"},
	SB = {Name = "Solomon Islands", Flag = "🇸🇧"},
	ET = {Name = "Ethiopia", Flag = "🇪🇹"},
	SO = {Name = "Somalia", Flag = "🇸🇴"},
	ZW = {Name = "Zimbabwe", Flag = "🇿🇼"},
	SA = {Name = "Saudi Arabia", Flag = "🇸🇦"},
	ES = {Name = "Spain", Flag = "🇪🇸"},
	ER = {Name = "Eritrea", Flag = "🇪🇷"},
	ME = {Name = "Montenegro", Flag = "🇲🇪"},
	MD = {Name = "Moldova", Flag = "🇲🇩"},
	MG = {Name = "Madagascar", Flag = "🇲🇬"},
	MF = {Name = "Saint Martin", Flag = "🇲🇫"},
	MA = {Name = "Morocco", Flag = "🇲🇦"},
	MC = {Name = "Monaco", Flag = "🇲🇨"},
	UZ = {Name = "Uzbekistan", Flag = "🇺🇿"},
	MM = {Name = "Myanmar", Flag = "🇲🇲"},
	ML = {Name = "Mali", Flag = "🇲🇱"},
	MO = {Name = "Macao", Flag = "🇲🇴"},
	MN = {Name = "Mongolia", Flag = "🇲🇳"},
	MH = {Name = "Marshall Islands", Flag = "🇲🇭"},
	MK = {Name = "Macedonia", Flag = "🇲🇰"},
	MU = {Name = "Mauritius", Flag = "🇲🇺"},
	MT = {Name = "Malta", Flag = "🇲🇹"},
	MW = {Name = "Malawi", Flag = "🇲🇼"},
	MV = {Name = "Maldives", Flag = "🇲🇻"},
	MQ = {Name = "Martinique", Flag = "🇲🇶"},
	MP = {Name = "Northern Mariana Islands", Flag = "🇲🇵"},
	MS = {Name = "Montserrat", Flag = "🇲🇸"},
	MR = {Name = "Mauritania", Flag = "🇲🇦"},
	IM = {Name = "Isle of Man", Flag = "🇮🇲"},
	UG = {Name = "Uganda", Flag = "🇺🇬"},
	TZ = {Name = "Tanzania", Flag = "🇹🇿"},
	MY = {Name = "Malaysia", Flag = "🇲🇾"},
	MX = {Name = "Mexico", Flag = "🇲🇽"},
	IL = {Name = "Israel", Flag = "🇮🇱"},
	FR = {Name = "France", Flag = "🇫🇷"},
	IO = {Name = "British Indian Ocean Territory", Flag = "🇮🇴"},
	SH = {Name = "Saint Helena", Flag = "🇸🇭"},
	FI = {Name = "Finland", Flag = "🇫🇮"},
	FJ = {Name = "Fiji", Flag = "🇫🇯"},
	FK = {Name = "Falkland Islands", Flag = "🇫🇰"},
	FM = {Name = "Micronesia", Flag = "🇫🇲"},
	FO = {Name = "Faroe Islands", Flag = "🇫🇴"},
	NI = {Name = "Nicaragua", Flag = "🇳🇮"},
	NL = {Name = "Netherlands", Flag = "🇳🇱"},
	NO = {Name = "Norway", Flag = "🇳🇴"},
	NA = {Name = "Namibia", Flag = "🇳🇦"},
	VU = {Name = "Vanuatu", Flag = "🇻🇺"},
	NC = {Name = "New Caledonia", Flag = "🇳🇨"},
	NE = {Name = "Niger", Flag = "🇳🇪"},
	NF = {Name = "Norfolk Island", Flag = "🇳🇫"},
	NG = {Name = "Nigeria", Flag = "🇳🇬"},
	NZ = {Name = "New Zealand", Flag = "🇳🇿"},
	NP = {Name = "Nepal", Flag = "🇳🇵"},
	NR = {Name = "Nauru", Flag = "🇳🇷"},
	NU = {Name = "Niue", Flag = "🇳🇺"},
	CK = {Name = "Cook Islands", Flag = "🇨🇰"},
	XK = {Name = "Kosovo", Flag = "🇽🇰"},
	CI = {Name = "Ivory Coast", Flag = "🇨🇮"},
	CH = {Name = "Switzerland", Flag = "🇨🇭"},
	CO = {Name = "Colombia", Flag = "🇨🇴"},
	CN = {Name = "China", Flag = "🇨🇳"},
	CM = {Name = "Cameroon", Flag = "🇨🇲"},
	CL = {Name = "Chile", Flag = "🇨🇱"},
	CC = {Name = "Cocos Islands", Flag = "🇨🇨"},
	CA = {Name = "Canada", Flag = "🇨🇦"},
	CG = {Name = "Republic of the Congo", Flag = "🇨🇬"},
	CF = {Name = "Central African Republic", Flag = "🇨🇫"},
	CD = {Name = "Democratic Republic of the Congo", Flag = "🇨🇩"},
	CZ = {Name = "Czech Republic", Flag = "🇨🇿"},
	CY = {Name = "Cyprus", Flag = "🇨🇾"},
	CX = {Name = "Christmas Island", Flag = "🇨🇽"},
	CR = {Name = "Costa Rica", Flag = "🇨🇷"},
	CW = {Name = "Curacao", Flag = "🇨🇼"},
	CV = {Name = "Cape Verde", Flag = "🇨🇻"},
	CU = {Name = "Cuba", Flag = "🇨🇺"},
	SZ = {Name = "Swaziland", Flag = "🇸🇿"},
	SY = {Name = "Syria", Flag = "🇸🇾"},
	SX = {Name = "Sint Maarten", Flag = "🇸🇽"},
	KG = {Name = "Kyrgyzstan", Flag = "🇰🇬"},
	KE = {Name = "Kenya", Flag = "🇰🇪"},
	SS = {Name = "South Sudan", Flag = "🇸🇸"},
	SR = {Name = "Suriname", Flag = "🇸🇷"},
	KI = {Name = "Kiribati", Flag = "🇰🇮"},
	KH = {Name = "Cambodia", Flag = "🇰🇭"},
	KN = {Name = "Saint Kitts and Nevis", Flag = "🇰🇳"},
	KM = {Name = "Comoros", Flag = "🇰🇲"},
	ST = {Name = "Sao Tome and Principe", Flag = "🇸🇹"},
	SK = {Name = "Slovakia", Flag = "🇸🇰"},
	KR = {Name = "South Korea", Flag = "🇰🇷"},
	SI = {Name = "Slovenia", Flag = "🇸🇮"},
	KP = {Name = "North Korea", Flag = "🇰🇵"},
	KW = {Name = "Kuwait", Flag = "🇰🇼"},
	SN = {Name = "Senegal", Flag = "🇸🇳"},
	SM = {Name = "San Marino", Flag = "🇸🇲"},
	SL = {Name = "Sierra Leone", Flag = "🇸🇱"},
	SC = {Name = "Seychelles", Flag = "🇸🇨"},
	KZ = {Name = "Kazakhstan", Flag = "🇰🇿"},
	KY = {Name = "Cayman Islands", Flag = "🇰🇾"},
	SG = {Name = "Singapore", Flag = "🇸🇬"},
	SE = {Name = "Sweden", Flag = "🇸🇪"},
	SD = {Name = "Sudan", Flag = "🇸🇩"},
	DO = {Name = "Dominican Republic", Flag = "🇩🇴"},
	DM = {Name = "Dominica", Flag = "🇩🇲"},
	DJ = {Name = "Djibouti", Flag = "🇩🇯"},
	DK = {Name = "Denmark", Flag = "🇩🇰"},
	VG = {Name = "British Virgin Islands", Flag = "🇻🇬"},
	DE = {Name = "Germany", Flag = "🇩🇪"},
	YE = {Name = "Yemen", Flag = "🇾🇪"},
	DZ = {Name = "Algeria", Flag = "🇩🇿"},
	US = {Name = "United States", Flag = "🇺🇸"},
	UY = {Name = "Uruguay", Flag = "🇺🇾"},
	YT = {Name = "Mayotte", Flag = "🇾🇹"},
	UM = {Name = "United States Minor Outlying Islands", Flag = "🇺🇲"},
	LB = {Name = "Lebanon", Flag = "🇱🇧"},
	LC = {Name = "Saint Lucia", Flag = "🇱🇨"},
	LA = {Name = "Laos", Flag = "🇱🇦"},
	TV = {Name = "Tuvalu", Flag = "🇹🇻"},
	TW = {Name = "Taiwan", Flag = "🇹🇼"},
	TT = {Name = "Trinidad and Tobago", Flag = "🇹🇹"},
	TR = {Name = "Turkey", Flag = "🇹🇷"},
	LK = {Name = "Sri Lanka", Flag = "🇱🇰"},
	LI = {Name = "Liechtenstein", Flag = "🇱🇮"},
	LV = {Name = "Latvia", Flag = "🇱🇻"},
	TO = {Name = "Tonga", Flag = "🇹🇴"},
	LT = {Name = "Lithuania", Flag = "🇱🇹"},
	LU = {Name = "Luxembourg", Flag = "🇱🇺"},
	LR = {Name = "Liberia", Flag = "🇱🇷"},
	LS = {Name = "Lesotho", Flag = "🇱🇸"},
	TH = {Name = "Thailand", Flag = "🇹🇭"},
	TF = {Name = "French Southern Territories", Flag = "🇹🇫"},
	TG = {Name = "Togo", Flag = "🇹🇬"},
	TD = {Name = "Chad", Flag = "🇹🇩"},
	TC = {Name = "Turks and Caicos Islands", Flag = "🇹🇨"},
	LY = {Name = "Libya", Flag = "🇱🇾"},
	VA = {Name = "Vatican", Flag = "🇻🇦"},
	VC = {Name = "Saint Vincent and the Grenadines", Flag = "🇻🇨"},
	AE = {Name = "United Arab Emirates", Flag = "🇦🇪"},
	AD = {Name = "Andorra", Flag = "🇦🇩"},
	AG = {Name = "Antigua and Barbuda", Flag = "🇦🇬"},
	AF = {Name = "Afghanistan", Flag = "🇦🇫"},
	AI = {Name = "Anguilla", Flag = "🇦🇮"},
	VI = {Name = "U.S. Virgin Islands", Flag = "🇻🇮"},
	IS = {Name = "Iceland", Flag = "🇮🇸"},
	IR = {Name = "Iran", Flag = "🇮🇷"},
	AM = {Name = "Armenia", Flag = "🇦🇲"},
	AL = {Name = "Albania", Flag = "🇦🇱"},
	AO = {Name = "Angola", Flag = "🇦🇴"},
	AQ = {Name = "Antarctica", Flag = "🇦🇶"},
	AS = {Name = "American Samoa", Flag = "🇦🇸"},
	AR = {Name = "Argentina", Flag = "🇦🇷"},
	AU = {Name = "Australia", Flag = "🇦🇺"},
	AT = {Name = "Austria", Flag = "🇦🇹"},
	AW = {Name = "Aruba", Flag = "🇦🇼"},
	IN = {Name = "India", Flag = "🇮🇳"},
	AX = {Name = "Aland Islands", Flag = "🇦🇽"},
	AZ = {Name = "Azerbaijan", Flag = "🇦🇿"},
	IE = {Name = "Ireland", Flag = "🇮🇪"},
	ID = {Name = "Indonesia", Flag = "🇮🇩"},
	UA = {Name = "Ukraine", Flag = "🇺🇦"},
	QA = {Name = "Qatar", Flag = "🇶🇦"},
	MZ = {Name = "Mozambique", Flag = "🇲🇿"},
}

Countries.CountryCodes = {}

for code in countryList do
	table.insert(Countries.CountryCodes, code)
end

Countries.CountryNames = {}

for _, country in countryList do
	table.insert(Countries.CountryNames, country.Name)
end

table.sort(Countries.CountryCodes, function(a: any, b: any)
	return a < b
end)

table.sort(Countries.CountryNames, function(a: any, b: any)
	return a < b
end)

function Countries:get_country_code_from_name(name)
	for code, country in pairs(countryList) do
		if country.Name == name then
			return code
		end
	end

	return nil
end

function Countries:get_country_name_from_code(code: any)
	return countryList[code].Name
end

function Countries:get_country_flag_from_code(code: any)
	return countryList[code].Flag
end

function Countries:get_country_info_from_code(code: any)
	return countryList[code]
end

function Countries:get_country_info_from_name(name: any)
	for code, country in pairs(countryList) do
		if country.Name == name then
			return country
		end
	end

	return nil
end

function Countries:get_country_flag_from_name(name: any)
	for code, country in pairs(countryList) do
		if country.Name == name then
			return country.Flag
		end
	end

	return nil
end

return Countries
