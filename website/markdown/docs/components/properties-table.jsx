/** @jsx jsx */
import { jsx, Styled } from 'theme-ui'

import React from 'react'
import ReactMarkdown from 'react-markdown'

const PropertiesTable = ({ properties }) => {
  const borderStyle = {
    border: theme => `1px solid ${theme.colors.gray5}`,
    borderCollapse: 'collapse',
  }
  const cellStyle = {
    ...borderStyle,
    p: 2,
  }
  return (
    <table
      sx={{
        ...borderStyle,
        my: 3,
      }}
    >
      <tr sx={{ bg: 'gray6', ...borderStyle, display: ['none', 'table-row'] }}>
        <th sx={{ ...cellStyle }}>Property</th>
        <th sx={{ ...cellStyle }}>Description</th>
        <th sx={{ ...cellStyle }}>Type</th>
        <th sx={{ ...cellStyle }}>Optional</th>
        <th sx={{ ...cellStyle }}>Default</th>
      </tr>

      <tbody>
        {properties.map((prop, index) => {
          let type
          if (prop.typeLink) {
            type = <a href={prop.typeLink}>{prop.type}</a>
          } else {
            type = <span>{prop.type}</span>
          }

          const optionalValue = prop.optional ? 'Yes' : 'No'

          return (
            <tr key={index} sx={{ ...borderStyle }}>
              <td sx={{ ...cellStyle }}>
                <div sx={{ fontWeight: ['bold', 'body'] }}>{prop.name}</div>
                <div sx={{ display: ['block', 'none'] }}>
                  <ReactMarkdown source={prop.description} />
                </div>
                <div sx={{ display: ['block', 'none'], mt: 3 }}>
                  <span sx={{ fontWeight: 'bold' }}>Type: </span>{' '}
                  <Styled.code>{type}</Styled.code>
                </div>
                <div sx={{ display: ['block', 'none'] }}>
                  <span sx={{ fontWeight: 'bold' }}>Optional: </span>{' '}
                  {optionalValue}
                </div>
                <div sx={{ display: ['block', 'none'] }}>
                  <span sx={{ fontWeight: 'bold' }}>Default value: </span>{' '}
                  {prop.default != '' && (
                    <Styled.code>{prop.default}</Styled.code>
                  )}
                </div>
              </td>
              <td sx={{ ...cellStyle, display: ['none', 'table-cell'] }}>
                <ReactMarkdown source={prop.description} />
              </td>
              <td sx={{ ...cellStyle, display: ['none', 'table-cell'] }}>
                <Styled.code>{type}</Styled.code>
              </td>
              <td sx={{ ...cellStyle, display: ['none', 'table-cell'] }}>
                {optionalValue}
              </td>
              <td sx={{ ...cellStyle, display: ['none', 'table-cell'] }}>
                {prop.default != '' && (
                  <Styled.code>{prop.default}</Styled.code>
                )}
              </td>
            </tr>
          )
        })}
      </tbody>
    </table>
  )
}

export default PropertiesTable
