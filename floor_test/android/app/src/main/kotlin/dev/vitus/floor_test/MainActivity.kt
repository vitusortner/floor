package dev.vitus.floor_test

import android.os.Bundle
import dev.flutter.plugins.integration_test.IntegrationTestPlugin
import io.flutter.app.FlutterActivity

class MainActivity: FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        IntegrationTestPlugin.registerWith(
            registrarFor("dev.flutter.plugins.integration_test.IntegrationTestPlugin"))
    }
}
