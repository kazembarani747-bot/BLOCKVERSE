package com.blockverse.app

import android.app.Activity
import android.os.Bundle
import android.view.Gravity
import android.widget.TextView

class MainActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val textView = TextView(this).apply {
            text = "BLOCKVERSE\nپروژه با موفقیت اجرا شد! 🚀"
            textSize = 24f
            gravity = Gravity.CENTER
            setPadding(32, 32, 32, 32)
        }

        setContentView(textView)
    }
}
