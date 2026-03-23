import { Application } from "@hotwired/stimulus"

import ThemeController from "./theme_controller"
import DropdownController from "./dropdown_controller"
import SdkIntegrationController from "./sdk_integration_controller"
import ClipboardController from "./clipboard_controller"
import TomSelectController from "./tom_select_controller"
import FlatpickrController from "./flatpickr_controller"
import SystemMonitorController from "./system_monitor_controller"
import FlashController from "./flash_controller"
import WechatLoginController from "./wechat_login_controller"
import WechatPayController from "./wechat_pay_controller"
import WechatPayModalController from "./wechat_pay_modal_controller"
import WechatJsapiPayController from "./wechat_jsapi_pay_controller"
import ProfileSetupController from "./profile_setup_controller"
import ProfileEditController from "./profile_edit_controller"
import LawFirmAutocompleteController from "./law_firm_autocomplete_controller"

const application = Application.start()

application.register("theme", ThemeController)
application.register("dropdown", DropdownController)
application.register("sdk-integration", SdkIntegrationController)
application.register("clipboard", ClipboardController)
application.register("tom-select", TomSelectController)
application.register("flatpickr", FlatpickrController)
application.register("system-monitor", SystemMonitorController)
application.register("flash", FlashController)
application.register("wechat-login", WechatLoginController)
application.register("wechat-pay", WechatPayController)
application.register("wechat-pay-modal", WechatPayModalController)
application.register("wechat-jsapi-pay", WechatJsapiPayController)
application.register("profile-setup", ProfileSetupController)
application.register("profile-edit", ProfileEditController)
application.register("law-firm-autocomplete", LawFirmAutocompleteController)

window.Stimulus = application
