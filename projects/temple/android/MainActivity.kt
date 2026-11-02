package com.temple.myapp

import android.Manifest
import android.app.Activity
import android.content.ClipData
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Base64
import android.webkit.GeolocationPermissions
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Toast
import android.window.OnBackInvokedCallback
import java.io.File
import java.io.FileOutputStream

/**
 * Temple's native shell: a thin guard around the one-file core (assets/index.html).
 * The shell owns exactly three things the page cannot do for itself —
 * the location permission prompt, the system share sheet for snapshot cards,
 * and the Android back button. Everything else is the page's own business.
 */
class MainActivity : Activity() {

    private lateinit var web: WebView
    private var pendingGeo: GeolocationPermissions.Callback? = null
    private var pendingOrigin: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.statusBarColor = Color.BLACK
        window.navigationBarColor = Color.BLACK

        web = WebView(this)
        setContentView(web)

        val s = web.settings
        s.javaScriptEnabled = true
        s.domStorageEnabled = true
        @Suppress("DEPRECATION") s.databaseEnabled = true
        s.setGeolocationEnabled(true)
        s.allowFileAccess = true
        s.mediaPlaybackRequiresUserGesture = true

        web.addJavascriptInterface(TempleBridge(), "TempleBridge")

        web.webViewClient = object : WebViewClient() {
            override fun onPageFinished(view: WebView, url: String) {
                view.evaluateJavascript(SHARE_SHIM, null)
            }
        }
        web.webChromeClient = object : WebChromeClient() {
            override fun onGeolocationPermissionsShowPrompt(
                origin: String,
                callback: GeolocationPermissions.Callback
            ) {
                val fine = checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) ==
                    PackageManager.PERMISSION_GRANTED
                val coarse = checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) ==
                    PackageManager.PERMISSION_GRANTED
                if (fine || coarse) {
                    callback.invoke(origin, true, false)
                } else {
                    pendingGeo = callback
                    pendingOrigin = origin
                    requestPermissions(
                        arrayOf(
                            Manifest.permission.ACCESS_FINE_LOCATION,
                            Manifest.permission.ACCESS_COARSE_LOCATION
                        ),
                        REQ_GEO
                    )
                }
            }
        }
        if (Build.VERSION.SDK_INT >= 33) {
            onBackInvokedDispatcher.registerOnBackInvokedCallback(
                0, // PRIORITY_DEFAULT (the API-36 stub omits the named constant; 0 is its value)
                OnBackInvokedCallback { handleBack() }
            )
        }
        web.loadUrl("file:///android_asset/index.html")
    }

    /** Back steps out of the app's own views first; only at home does it leave the app. */
    private fun handleBack() {
        web.evaluateJavascript(
            "(function(){var b=document.getElementById('backBtn');" +
                "if(b&&!b.classList.contains('hidden')){b.click();return 'nav';}return 'exit';})()"
        ) { r ->
            if (r != null && r.contains("exit")) finish()
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQ_GEO) {
            val granted = grantResults.any { it == PackageManager.PERMISSION_GRANTED }
            pendingGeo?.invoke(pendingOrigin, granted, false)
            pendingGeo = null
            pendingOrigin = null
        }
    }

    @Suppress("DEPRECATION")
    @Deprecated("Superseded by the OnBackInvokedCallback registered in onCreate for API 33+")
    override fun onBackPressed() {
        handleBack()
    }

    inner class TempleBridge {
        /** The page hands over a finished snapshot (data URL); the shell puts it in the share sheet. */
        @JavascriptInterface
        fun shareImage(dataUrl: String, name: String) {
            runOnUiThread {
                try {
                    val bytes = Base64.decode(dataUrl.substringAfter("base64,", ""), Base64.DEFAULT)
                    val dir = File(cacheDir, "shared").apply { mkdirs() }
                    val safe = name.replace(Regex("[^A-Za-z0-9._-]"), "-")
                    val f = File(dir, safe)
                    FileOutputStream(f).use { it.write(bytes) }
                    val uri = Uri.parse("content://" + packageName + ".fileprovider/shared/" + f.name)
                    val send = Intent(Intent.ACTION_SEND).apply {
                        type = "image/png"
                        putExtra(Intent.EXTRA_STREAM, uri)
                        clipData = ClipData.newRawUri("temple-verse", uri)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    startActivity(Intent.createChooser(send, "Send this verse"))
                } catch (e: Exception) {
                    Toast.makeText(this@MainActivity, "That snapshot could not be shared.", Toast.LENGTH_LONG).show()
                }
            }
        }
    }

    companion object {
        private const val REQ_GEO = 41

        // WebView has no navigator.share; give the page one that ends at the bridge,
        // so the verse tools' snapshot button keeps its exact behavior inside the APK.
        private const val SHARE_SHIM = """
(function(){
  try{
    if(window.TempleBridge && !navigator.share){
      var shareFn = function(data){
        return new Promise(function(resolve, reject){
          var f = data && data.files && data.files[0];
          if(!f){ reject(new Error('nothing to share')); return; }
          var r = new FileReader();
          r.onload = function(){
            try{ TempleBridge.shareImage(String(r.result), f.name || 'temple-verse.png'); resolve(); }
            catch(e){ reject(e); }
          };
          r.onerror = function(){ reject(new Error('read failed')); };
          r.readAsDataURL(f);
        });
      };
      try{ navigator.share = shareFn; }catch(e){}
      try{ navigator.canShare = function(){ return true; }; }catch(e){}
      if(!navigator.share){ Object.defineProperty(navigator, 'share', {value: shareFn, configurable: true}); }
      if(!navigator.canShare){ Object.defineProperty(navigator, 'canShare', {value: function(){ return true; }, configurable: true}); }
    }
  }catch(e){}
})();
"""
    }
}
