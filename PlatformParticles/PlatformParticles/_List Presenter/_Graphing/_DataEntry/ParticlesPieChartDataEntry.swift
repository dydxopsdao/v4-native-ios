//
//  ParticlesCandleChartDataEntry.swift
//  PlatformParticles
//
//  Created by Qiang Huang on 10/8/21.
//  Copyright © 2021 dYdX Trading Inc. All rights reserved.
//

import DGCharts
import ParticlesKit
import Utilities

@objc public class ParticlesPieChartDataEntry: PieChartDataEntry, ParticlesChartDataEntryProtocol {
    public var dataSet: Weak<ChartDataSet> = Weak<ChartDataSet>()
    public var notifierDebouncer: Debouncer = Debouncer()

    private var pieData: PieGraphingObjectProtocol? {
        return model as? PieGraphingObjectProtocol
    }

    override open func sync() {
        if let graphing = model as? PieGraphingObjectProtocol {
            if let value = graphing.pieLabel {
                label = value
            }
            if let value = graphing.pieY?.doubleValue {
               y = value
            }
        }
    }
}
