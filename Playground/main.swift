//
//  main.swift
//  
//
//  Created by Dzmitry Letko on 05/10/2023.
//

import Foundation
import SecureBoxOpen

print(try JSONSerialization.jsonObject(with: SecureBox.exampleJson.open(), options: []))
print(try JSONSerialization.jsonObject(with: SecureBox.exampleCopy2Json.open(), options: []))
