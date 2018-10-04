<?php
/**
 * DokuWiki Plugin upgrade (Admin Component)
 *
 * @license GPL 2 http://www.gnu.org/licenses/gpl-2.0.html
 * @author  Andreas Gohr <andi@splitbrain.org>
 */

// must be run within Dokuwiki
if(!defined('DOKU_INC')) die();
if(!defined('DOKU_PLUGIN')) define('DOKU_PLUGIN', DOKU_INC.'lib/plugins/');
require_once DOKU_PLUGIN.'admin.php';
require_once DOKU_PLUGIN.'upgrade/VerboseTarLib.class.php';
require_once DOKU_PLUGIN.'upgrade/HTTPClient.php';

use dokuwiki\plugin\upgrade\DokuHTTPClient;

class admin_plugin_upgrade extends DokuWiki_Admin_Plugin {
    private $tgzurl;
    private $tgzfile;
    private $tgzdir;
    private $tgzversion;
    private $pluginversion;

    protected $haderrors = false;

    public function __construct() {
        global $conf;

        $branch = 'stable';

        $this->tgzurl        = "https://github.com/splitbrain/dokuwiki/archive/$branch.tar.gz";
        $this->tgzfile       = $conf['tmpdir'].'/dokuwiki-upgrade.tgz';
        $this->tgzdir        = $conf['tmpdir'].'/dokuwiki-upgrade/';
        $this->tgzversion    = "https://raw.githubusercontent.com/splitbrain/dokuwiki/$branch/VERSION";
        $this->pluginversion = "https://raw.githubusercontent.com/splitbrain/dokuwiki-plugin-upgrade/master/plugin.info.txt";
    }

    public function getMenuSort() {
        return 555;
    }

    public function handle() {
        if($_REQUEST['step'] && !checkSecurityToken()) {
            unset($_REQUEST['step']);
        }
    }

    public function html() {
        $abrt = false;
        $next = false;

        echo '<h1>'.$this->getLang('menu').'</h1>';

        $this->_say('<div id="plugin__upgrade">');
        // enable auto scroll
        ?>
        <script language="javascript" type="text/javascript">
            var plugin_upgrade = window.setInterval(function () {
                var obj = document.getElementById('plugin__upgrade');
                if (obj) obj.scrollTop = obj.scrollHeight;
            }, 25);
        </script>
        <?php

        // handle current step
        $this->_stepit($abrt, $next);

        // disable auto scroll
        ?>
        <script language="javascript" type="text/javascript">
            window.setTimeout(function () {
                window.clearInterval(plugin_upgrade);
            }, 50);
        </script>
        <?php
        $this->_say('</div>');

        $careful = '';
        if($this->haderrors) {
            echo '<div id="plugin__upgrade_careful">'.$this->getLang('careful').'</div>';
            $careful = 'careful';
        }

        $action = script();
        echo '<form action="' . $action . '" method="post" id="plugin__upgrade_form">';
        echo '<input type="hidden" name="do" value="admin" />';
        echo '<input type="hidden" name="page" value="upgrade" />';
        echo '<input type="hidden" name="sectok" value="' . getSecurityToken() . '" />';
        if($next) echo '<button type="submit" name="step[' . $next . ']" value="1" class="button continue '.$careful.'">' . $this->getLang('btn_continue') . ' ➡</button>';
        if($abrt) echo '<button type="submit" name="step[cancel]" value="1" class="button abort">✖ ' . $this->getLang('btn_abort') . '</button>';
        echo '</form>';

        $this->_progress($next);
    }

    /**
     * Display a progress bar of all steps
     *
     * @param string $next the next step
     */
    private function _progress($next) {
        $steps  = array('version', 'download', 'unpack', 'check', 'upgrade');
        $active = true;
        $count = 0;

        echo '<div id="plugin__upgrade_meter"><ol>';
        foreach($steps as $step) {
            $count++;
            if($step == $next) $active = false;
            if($active) {
                echo '<li class="active">';
                echo '<span class="step">✔</span>';
            } else {
                echo '<li>';
                echo '<span class="step">'.$count.'</span>';
            }

            echo '<span class="stage">'.$this->getLang('step_'.$step).'</span>';
            echo '</li>';
        }
        echo '</ol></div>';
    }

    /**
     * Decides the current step and executes it
     *
     * @param bool $abrt
     * @param bool $next
     */
    private function _stepit(&$abrt, &$next) {

        if(isset($_REQUEST['step']) && is_array($_REQUEST['step'])) {
            $step = array_shift(array_keys($_REQUEST['step']));
        } else {
            $step = '';
        }

        if($step == 'cancel' || $step == 'done') {
            # cleanup
            @unlink($this->tgzfile);
            $this->_rdel($this->tgzdir);
            if($step == 'cancel') $step = '';
        }

        if($step) {
            $abrt = true;
            $next = false;
            if($step == 'version') {
                $this->_step_version();
                $next = 'download';
            } elseif ($step == 'done') {
                $this->_step_done();
                $next = '';
                $abrt = '';
            } elseif(!file_exists($this->tgzfile)) {
                if($this->_step_download()) $next = 'unpack';
            } elseif(!is_dir($this->tgzdir)) {
                if($this->_step_unpack()) $next = 'check';
            } elseif($step != 'upgrade') {
                if($this->_step_check()) $next = 'upgrade';
            } elseif($step == 'upgrade') {
                if($this->_step_copy()) {
                    $next = 'done';
                    $abrt = '';
                }
            } else {
                echo 'uhm. what happened? where am I? This should not happen';
            }
        } else {
            # first time run, show intro
            echo $this->locale_xhtml('step0');
            $abrt = false;
            $next = 'version';
        }
    }

    /**
     * Output the given arguments using vsprintf and flush buffers
     */
    public function _say() {
        $args = func_get_args();
        echo '<img src="'.DOKU_BASE.'lib/images/blank.gif" width="16" height="16" alt="" /> ';
        echo vsprintf(array_shift($args)."<br />\n", $args);
        flush();
        ob_flush();
    }

    /**
     * Print a warning using the given arguments with vsprintf and flush buffers
     */
    public function _warn() {
        $this->haderrors = true;

        $args = func_get_args();
        echo '<img src="'.DOKU_BASE.'lib/images/error.png" width="16" height="16" alt="!" /> ';
        echo vsprintf(array_shift($args)."<br />\n", $args);
        flush();
        ob_flush();
    }

    /**
     * Recursive delete
     *
     * @author Jon Hassall
     * @link   http://de.php.net/manual/en/function.unlink.php#87045
     */
    private function _rdel($dir) {
        if(!$dh = @opendir($dir)) {
            return false;
        }
        while(false !== ($obj = readdir($dh))) {
            if($obj == '.' || $obj == '..') continue;

            if(!@unlink($dir.'/'.$obj)) {
                $this->_rdel($dir.'/'.$obj);
            }
        }
        closedir($dh);
        return @rmdir($dir);
    }

    /**
     * Check various versions
     *
     * @return bool
     */
    private function _step_version() {
        $ok = true;

        // we need SSL - only newer HTTPClients check that themselves
        if(!in_array('ssl', stream_get_transports())) {
            $this->_warn($this->getLang('vs_ssl'));
            $ok = false;
        }

        // get the available version
        $http       = new DokuHTTPClient();
        $tgzversion = $http->get($this->tgzversion);
        if(!$tgzversion) {
            $this->_warn($this->getLang('vs_tgzno').' '.hsc($http->error));
            $ok = false;
        }
        if(!preg_match('/(^| )(\d\d\d\d-\d\d-\d\d[a-z]*)( |$)/i', $tgzversion, $m)) {
            $this->_warn($this->getLang('vs_tgzno'));
            $ok            = false;
            $tgzversionnum = 0;
        } else {
            $tgzversionnum = $m[2];
            $this->_say($this->getLang('vs_tgz'), $tgzversion);
        }

        // get the current version
        $version = getVersion();
        if(!preg_match('/(^| )(\d\d\d\d-\d\d-\d\d[a-z]*)( |$)/i', $version, $m)) {
            $versionnum = 0;
        } else {
            $versionnum = $m[2];
        }
        $this->_say($this->getLang('vs_local'), $version);

        // compare versions
        if(!$versionnum) {
            $this->_warn($this->getLang('vs_localno'));
            $ok = false;
        } else if($tgzversionnum) {
            if($tgzversionnum < $versionnum) {
                $this->_warn($this->getLang('vs_newer'));
                $ok = false;
            } elseif($tgzversionnum == $versionnum) {
                $this->_warn($this->getLang('vs_same'));
                $ok = false;
            }
        }

        // check plugin version
        $pluginversion = $http->get($this->pluginversion);
        if($pluginversion) {
            $plugininfo = linesToHash(explode("\n", $pluginversion));
            $myinfo     = $this->getInfo();
            if($plugininfo['date'] > $myinfo['date']) {
                $this->_warn($this->getLang('vs_plugin'), $plugininfo['date']);
                $ok = false;
            }
        }

        // check if PHP is up to date
        $minphp = '5.6';
        if(version_compare(phpversion(), $minphp, '<')) {
            $this->_warn($this->getLang('vs_php'), $minphp, phpversion());
            $ok = false;
        }

        return $ok;
    }

    /**
     * Redirect to the start page
     */
    private function _step_done() {
        if (function_exists('opcache_reset')) {
            opcache_reset();
        }
        echo $this->getLang('finish');
        echo "<script type='text/javascript'>location.href='".DOKU_URL."';</script>";
    }

    /**
     * Download the tarball
     *
     * @return bool
     */
    private function _step_download() {
        $this->_say($this->getLang('dl_from'), $this->tgzurl);

        @set_time_limit(300);
        @ignore_user_abort();

        $http          = new DokuHTTPClient();
        $http->timeout = 300;
        $data          = $http->get($this->tgzurl);

        if(!$data) {
            $this->_warn($http->error);
            $this->_warn($this->getLang('dl_fail'));
            return false;
        }

        if(!io_saveFile($this->tgzfile, $data)) {
            $this->_warn($this->getLang('dl_fail'));
            return false;
        }

        $this->_say($this->getLang('dl_done'), filesize_h(strlen($data)));

        return true;
    }

    /**
     * Unpack the tarball
     *
     * @return bool
     */
    private function _step_unpack() {
        $this->_say('<b>'.$this->getLang('pk_extract').'</b>');

        @set_time_limit(300);
        @ignore_user_abort();

        try {
            $tar = new VerboseTar();
            $tar->open($this->tgzfile);
            $tar->extract($this->tgzdir, 1);
            $tar->close();
        } catch (Exception $e) {
            $this->_warn($e->getMessage());
            $this->_warn($this->getLang('pk_fail'));
            return false;
        }

        $this->_say($this->getLang('pk_done'));

        $this->_say(
            $this->getLang('pk_version'),
            hsc(file_get_contents($this->tgzdir.'/VERSION')),
            getVersion()
        );
        return true;
    }

    /**
     * Check permissions of files to change
     *
     * @return bool
     */
    private function _step_check() {
        $this->_say($this->getLang('ck_start'));
        $ok = $this->_traverse('', true);
        if($ok) {
            $this->_say('<b>'.$this->getLang('ck_done').'</b>');
        } else {
            $this->_warn('<b>'.$this->getLang('ck_fail').'</b>');
        }
        return $ok;
    }

    /**
     * Copy over new files
     *
     * @return bool
     */
    private function _step_copy() {
        $this->_say($this->getLang('cp_start'));
        $ok = $this->_traverse('', false);
        if($ok) {
            $this->_say('<b>'.$this->getLang('cp_done').'</b>');
            $this->_rmold();
            $this->_say('<b>'.$this->getLang('finish').'</b>');
        } else {
            $this->_warn('<b>'.$this->getLang('cp_fail').'</b>');
        }
        return $ok;
    }

    /**
     * Delete outdated files
     */
    private function _rmold() {
        global $conf;

        $list = file($this->tgzdir.'data/deleted.files');
        foreach($list as $line) {
            $line = trim(preg_replace('/#.*$/', '', $line));
            if(!$line) continue;
            $file = DOKU_INC.$line;
            if(!file_exists($file)) continue;

            // check that the given file is an case sensitive match
            if(basename(realpath($file)) != basename($file)) {
                $this->_say($this->getLang('rm_mismatch'), hsc($line));
                continue;
            }

            if((is_dir($file) && $this->_rdel($file)) ||
                @unlink($file)
            ) {
                $this->_say($this->getLang('rm_done'), hsc($line));
            } else {
                $this->_warn($this->getLang('rm_fail'), hsc($line));
            }
        }
        // delete install
        @unlink(DOKU_INC.'install.php');

        // make sure update message will be gone
        @touch(DOKU_INC.'doku.php');
        @unlink($conf['cachedir'].'/messages.txt');
    }

    /**
     * Traverse over the given dir and compare it to the DokuWiki dir
     *
     * Checks what files need an update, tests for writability and copies
     *
     * @param string $dir
     * @param bool   $dryrun do not copy but only check permissions
     * @return bool
     */
    private function _traverse($dir, $dryrun) {
        $base = $this->tgzdir;
        $ok   = true;

        $dh = @opendir($base.'/'.$dir);
        if(!$dh) return false;
        while(($file = readdir($dh)) !== false) {
            if($file == '.' || $file == '..') continue;
            $from = "$base/$dir/$file";
            $to   = DOKU_INC."$dir/$file";

            if(is_dir($from)) {
                if($dryrun) {
                    // just check for writability
                    if(!is_dir($to)) {
                        if(is_dir(dirname($to)) && !is_writable(dirname($to))) {
                            $this->_warn('<b>'.$this->getLang('tv_noperm').'</b>', hsc("$dir/$file"));
                            $ok = false;
                        }
                    }
                }

                // recursion
                if(!$this->_traverse("$dir/$file", $dryrun)) {
                    $ok = false;
                }
            } else {
                $fmd5 = md5(@file_get_contents($from));
                $tmd5 = md5(@file_get_contents($to));
                if($fmd5 != $tmd5 || !file_exists($to)) {
                    if($dryrun) {
                        // just check for writability
                        if((file_exists($to) && !is_writable($to)) ||
                            (!file_exists($to) && is_dir(dirname($to)) && !is_writable(dirname($to)))
                        ) {

                            $this->_warn('<b>'.$this->getLang('tv_noperm').'</b>', hsc("$dir/$file"));
                            $ok = false;
                        } else {
                            $this->_say($this->getLang('tv_upd'), hsc("$dir/$file"));
                        }
                    } else {
                        // check dir
                        if(io_mkdir_p(dirname($to))) {
                            // remove existing (avoid case sensitivity problems)
                            if(file_exists($to) && !@unlink($to)) {
                                $this->_warn('<b>'.$this->getLang('tv_nodel').'</b>', hsc("$dir/$file"));
                                $ok = false;
                            }
                            // copy
                            if(!copy($from, $to)) {
                                $this->_warn('<b>'.$this->getLang('tv_nocopy').'</b>', hsc("$dir/$file"));
                                $ok = false;
                            } else {
                                $this->_say($this->getLang('tv_done'), hsc("$dir/$file"));
                            }
                        } else {
                            $this->_warn('<b>'.$this->getLang('tv_nodir').'</b>', hsc("$dir"));
                            $ok = false;
                        }
                    }
                }
            }
        }
        closedir($dh);
        return $ok;
    }
}

// vim:ts=4:sw=4:et:enc=utf-8:
