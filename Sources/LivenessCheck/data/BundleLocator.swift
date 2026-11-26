//
//  BundleLocator.swift
//  LivenessCheck
//

import Foundation

private final class BundleToken {}

extension Bundle {
    /// The bundle containing the SDK's image assets, resolved for both
    /// Swift Package Manager (`Bundle.module`) and CocoaPods
    /// (`LivenessCheck.bundle` produced by `resource_bundles`).
    static var livenessCheck: Bundle {
        #if SWIFT_PACKAGE
        return .module
        #else
        let containerBundle = Bundle(for: BundleToken.self)
        if let url = containerBundle.url(forResource: "LivenessCheck", withExtension: "bundle"),
           let bundle = Bundle(url: url) {
            return bundle
        }
        return containerBundle
        #endif
    }
}
