function openid_signin(provider)
{
    if (provider == 'google') {
        document.forms[0].user_openid_url.value="gmail.com";
        document.forms[0].submit();
    } else if (provider == 'yahoo') {
        document.forms[0].user_openid_url.value="yahoo.com";
        document.forms[0].submit();
    } else if (provider == 'myopenid') {
        document.forms[0].user_openid_url.value="myopenid.com";
        document.forms[0].submit();
    } else if (provider == 'wordpress') {
        document.forms[0].user_openid_url.value="wordpress.com";
        document.forms[0].submit();
    } else if (provider == 'myspace') {
        document.forms[0].user_openid_url.value="myspace.com";
        document.forms[0].submit();
    } else if (provider == 'openid') {
        document.forms[0].user_openid_url.value="http://";
    }

}
