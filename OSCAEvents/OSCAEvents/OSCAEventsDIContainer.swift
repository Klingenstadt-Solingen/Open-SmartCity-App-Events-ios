//
//  OSCAEventsDIContainer.swift
//  OSCAEvents
//
//  Created by Stephan Breidenbach on 16.02.22.
//

import Foundation

final class OSCAEventsDIContainer {
    private let dependencies: OSCAEventsDependencies
    
    public init(dependencies: OSCAEventsDependencies) {
        self.dependencies = dependencies
    }// end public init
}// end final class OSCAEventsDIContainer
