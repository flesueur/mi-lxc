<?php
/**
 * English language file for upgrade plugin
 *
 * @author Andreas Gohr <andi@splitbrain.org>
 */

// menu entry for admin plugins
$lang['menu'] = 'Wiki Upgrade';

// custom language strings for the plugin
$lang['vs_php']     = 'New DokuWiki releases need at least PHP %s, but you\'re running %s. You should upgrade your PHP version before upgrading!';
$lang['vs_tgzno']   = 'Could not determine the newest version of DokuWiki.';
$lang['vs_tgz']     = 'DokuWiki <b>%s</b> is available for download.';
$lang['vs_local']   = 'You\'re currently running DokuWiki <b>%s</b>.';
$lang['vs_localno'] = 'It\'s not clear how old your currently running version is, manual upgrade is recommended.';
$lang['vs_newer']   = 'It seems your current DokuWiki is even newer than the latest stable release. Upgrade not recommended.';
$lang['vs_same']    = 'Your current DokuWiki is already up to date. No need for upgrading.';
$lang['vs_plugin']  = 'There is a newer upgrade plugin available (%s) you should update the plugin before continuing.';
$lang['vs_ssl']     = 'Your PHP seems not to support SSL streams, downloading the needed data will most likely fail. Upgrade manually instead.';

$lang['dl_from']    = 'Downloading archive from %s...';
$lang['dl_fail']    = 'Download failed.';
$lang['dl_done']    = 'Download completed (%s).';
$lang['pk_extract'] = 'Unpacking archive...';
$lang['pk_fail']    = 'Unpacking failed.';
$lang['pk_done']    = 'Unpacking completed.';
$lang['pk_version'] = 'DokuWiki <b>%s</b> is ready to install (You\'re currently running <b>%s</b>).';
$lang['ck_start']   = 'Checking file permissions...';
$lang['ck_done']    = 'All files are writable. Ready to upgrade.';
$lang['ck_fail']    = 'Some files aren\'t writable. Automatic upgrade not possible.';
$lang['cp_start']   = 'Updating files...';
$lang['cp_done']    = 'All files updated.';
$lang['cp_fail']    = 'Uh-Oh. Something went wrong. Better check manually.';
$lang['tv_noperm']  = '<code>%s</code> is not writable!';
$lang['tv_upd']     = '<code>%s</code> will be updated.';
$lang['tv_nocopy']  = 'Could not copy file <code>%s</code>!';
$lang['tv_nocopy']  = 'Could not remove existing file <code>%s</code> before overwriting!';
$lang['tv_nodir']   = 'Could not create directory <code>%s</code>!';
$lang['tv_done']    = 'updated <code>%s</code>';
$lang['rm_done']    = 'Deprecated <code>%s</code> deleted.';
$lang['rm_fail']    = 'Could not delete deprecated <code>%s</code>. <b>Please delete manually!</b>';
$lang['rm_mismatch']= 'Case mismatch for deprecated file <code>%s</code>. Please check manually if file should really be deleted.';
$lang['finish']     = 'Upgrade completed. Enjoy your new DokuWiki';

$lang['btn_continue'] = 'Continue';
$lang['btn_abort']    = 'Abort';

$lang['step_version']  = 'Check';
$lang['step_download'] = 'Download';
$lang['step_unpack']   = 'Unpack';
$lang['step_check']    = 'Verify';
$lang['step_upgrade']  = 'Install';

$lang['careful'] = 'Errors above! You should <b>not</b> continue!';

//Setup VIM: ex: et ts=4 enc=utf-8 :
