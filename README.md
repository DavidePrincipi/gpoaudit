# Logon audit GPO

Syslog logon audit GPO for Active Directory

----

This guide is for a NethServer 7 system with local AD accounts provider. See also

 http://docs.nethserver.org/en/v7/accounts.html#samba-active-directory-local-provider-installation

## NSDC setup

We need to install and configure a syslog server on NSDC to receive logon/logoff
messages from the domain workstations.

1.  Install rsyslog

        yum --installroot=/var/lib/machines/nsdc  install rsyslog

2.  Copy `rsyslog.d/gpoaudit.conf` in this git repository to nsdc

        cp rsyslog.d/gpoaudit.conf /var/lib/machines/nsdc/etc/rsyslog.d/gpoaudit.conf

3.  Enable and start the service

        systemctl enable -M nsdc --now rsyslog

4.  (optional) send a test message and check it is appended to nsdc log

        logger -p authpriv.info -n $(config getprop nsdc IpAddress) -d -P 514 -t test helloworld
        tail /var/lib/machines/nsdc/var/log/secure

## GPO installation

Here we create and configure the GPO and copy the syslog client scripts into it.

1.  Get a shell on nsdc and create an empty GPO container, providing a Domain Admins member credentials

        [root@nsrv ~]# systemd-run -M nsdc -t bash
        Running as unit run-7046.service.
        Press ^] three times within 1s to disconnect TTY.
        bash-4.2# samba-tool gpo create "Logon audit GPO" -U nethesis --password TK04weo.
        GPO 'Logon audit GPO' created as {FB3DF807-0C09-45F5-926D-B6479A5EC9D3}

2.  From another shell, synchronize the GPO folder in this git repository with the GPO folder

        [root@nsrv ~]# rsync -ai --exclude=.gitignore --no-owner --no-group GPO/ /var/lib/machines/nsdc/var/lib/samba/sysvol/ad.example.com/Policies/\{FB3DF807-0C09-45F5-926D-B6479A5EC9D3\}/
        cd+++++++++ ./
        >f+++++++++ GPT.INI
        cd+++++++++ Machine/
        cd+++++++++ User/
        cd+++++++++ User/Scripts/
        >f+++++++++ User/Scripts/psscripts.ini
        >f+++++++++ User/Scripts/scripts.ini
        >f+++++++++ User/Scripts/syslogger.ps1
        cd+++++++++ User/Scripts/Logoff/
        cd+++++++++ User/Scripts/Logon/

3.  Go back to nsdc shell and link the GPO to the domain container

        bash-4.2# samba-tool ntacl sysvolreset && echo OK
        OK
        bash-4.2# ldbmodify -H /var/lib/samba/private/sam.ldb <<EOF
        dn: CN={FB3DF807-0C09-45F5-926D-B6479A5EC9D3},CN=Policies,CN=System,DC=ad,DC=example,DC=com
        changetype: modify
        replace: versionNumber
        versionNumber: 65536
        -
        replace: gPCUserExtensionNames
        gPCUserExtensionNames: [{42B5FAAE-6536-11D2-AE5A-0000F87571E3}{40B66650-4972-1
         1D1-A7CA-0000F87571E3}]
        EOF

    Note that `GPT.INI` contains the `versionNumber` in hexadecimal base,
    whilst `gPCUserExtensionNames` actually enables the logon/logff scripts
    section.

    Finally link the GPO to the whole domain container:

        bash-4.2# samba-tool gpo setlink DC=ad,DC=example,DC=com {FB3DF807-0C09-45F5-926D-B6479A5EC9D3} -U nethesis --password TK04weo.
        Added/Updated GPO link
        GPO(s) linked to DN DC=ad,DC=example,DC=com
            GPO     : {FB3DF807-0C09-45F5-926D-B6479A5EC9D3}
            Name    : Logon audit GPO
            Options : NONE

            GPO     : {31B2F340-016D-11D2-945F-00C04FB984F9}
            Name    : Default Domain Policy
            Options : NONE

## See also

About `gPCUserExtensionNames`:

- http://evilgpo.blogspot.com/2012/11/guids-guids-guids-2.html
- https://deployhappiness.com/cse-processing-order-know-lsdou-learn-this-too/