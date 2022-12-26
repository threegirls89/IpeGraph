% matlab2ipegraph.m
% 2022/04/13 ver.1.0.0 by S.Miyoshi
% matlabからipeとtikzで編集できるグラフを吐き出すプログラム
% 入力 グラフが描かれたfigureハンドル 図の出力サイズ [幅 高さ] 出力ファイル名（拡張子なし）
% 出力 グラフが描かれた出力ファイル名.ipeファイルとデータ列の出力ファイル名.txtファイルがいくつか

% 現在のところできていること
% plot, stairsへの対応
% 対数プロットへの対応
% 1つのfigureに2以上のaxisがある場合への対応

% これから対応したいこと
% bar
% 3次元 plot3, surf, etc.

function matlab2ipegraph(hfig, figuresize, filename)

    j=0;
    for i = 1:length(hfig.Children)
        if(strcmp(hfig.Children(i).Type, 'axes'))
            j=j+1;
            axs(j) = hfig.Children(i);
        end
    end

    % 軸ラベルの初期配置
    xlabelpos = [0 -4];
    ylabelpos = [-16 figuresize(2)];
    
    for i = 1:length(axs)
        plots = findplotinaxis(axs(i));
        colorstr = getColorsinPlots(plots);
        axistype = interpretaxistype(axs(i));
        
        [path, fname, ~] = fileparts(filename);
        if ~isempty(path) && isempty(dir(path))
            mkdir(path);
        end
        file = fopen(strcat(filename,num2str(i),'.ipe'), 'w');

        % preamble
        fprintf(file,'%s', ['<?xml version="1.0"?>' newline '<!DOCTYPE ipe SYSTEM "ipe.dtd">' newline '<ipe version="70218" creator="Ipe 7.2.24">' newline ...
            '<preamble>' newline '</preamble>' newline '<ipestyle name="ipegraph">' newline '<preamble>' newline '\usepackage{tikz}' newline '\usepackage{pgfplots}' newline ...
            '\newdimen\itgfigurewidth' newline '\newdimen\itgfigureheight' newline '</preamble>' newline '</ipestyle>' newline ...
            '<page>' newline '<layer name="alpha"/>' newline '<view layers="alpha" active="alpha"/>' newline ...
            '<text layer="alpha" matrix="1 0 0 1 0 0" transformations="translations" pos="0 0" stroke="black" type="minipage" width="', num2str(figuresize(1)), '" height="', num2str(figuresize(2)), '" depth="0" valign="top">' newline]);

        fprintf(file, '%s', ['\itgfigurewidth=\linewidth' newline '\advance \itgfigurewidth -24bp%change larger if the graph is wider than the text box' newline ...
            '\itgfigureheight= ' num2str(figuresize(2) / figuresize(1)) ' \itgfigurewidth' newline ...
            colorstr newline '\begin{tikzpicture}' newline '\begin{', axistype, '}' ...
        ]);

        % 軸
        fprintf(file, '%s', interpretaxis(axs(i)));

        % 軸に属するプロットたち 今のところ2次元のplot, stairsのみ対応
        % プロットの表示順と逆順ぽい
        for j = length(plots):-1:1
            writematrix([plots(j).XData.', plots(j).YData.'], sprintf('%s%d%d.txt', filename,i,j), 'Delimiter', ' ');
            fprintf(file,'\\addplot[%s,%s] table{%s};\n', interpretLine(plots(j), j), interpretMarker(plots(j), j), sprintf('%s%d%d.txt', fname,i,j));
        end

        % 凡例
        fprintf(file,'%s', ['\legend{' interpretlegend(axs(i).Legend) '}' newline]);

        % postamble
        fprintf(file, '%s', ['\end{', axistype, '}' newline '\end{tikzpicture}' newline '</text>' newline]);

        % 軸ラベル
        if(~isempty(axs(i).XLabel.String))
            fprintf(file, '%s', ['<text layer="alpha" matrix="1 0 0 1 0 0" transformations="rigid" pos="',num2str(xlabelpos - [0 figuresize(2)]),'" stroke="black" type="minipage" width="',num2str(figuresize(1)),'" height="0" depth="0" valign="top">\centering' newline axs(i).XLabel.String newline '</text>' newline]);
        end
        if(~isempty(axs(i).YLabel.String))
            fprintf(file, '%s', ['<text layer="alpha" matrix="0 1 -1 0 0 0" transformations="rigid" pos="', num2str(ylabelpos * [0 -1; -1 0]),'" stroke="black" type="minipage" width="',num2str(figuresize(2)),'" height="0" depth="0" valign="top">\centering' newline axs(i).YLabel.String newline '</text>' newline]);
        end

        fprintf(file, '</page>\n</ipe>\n');
        fclose(file);
    end

    disp('finished');

end

function axisstr = interpretaxis(ax)
    axisstr = ['[%' newline 'width=\itgfigurewidth,height=\itgfigureheight,' newline 'style={font=\footnotesize},' newline 'scale only axis,' newline,...
        'every outer x axis line/.append style={black},' newline 'every x tick/.append style={black},' newline 'xminorticks=true,' newline 'xmajorgrids,' newline,...
        'every outer y axis line/.append style={black},' newline 'every y tick/.append style={black},' newline 'yminorticks=true,' newline 'ymajorgrids,' newline,...
        'axis background/.style={fill=white},' newline,...
        'legend cell align=left,' newline];

    if(~isempty(ax.Legend))
%         axisstr = [axisstr 'legend pos=' ax.Legend.Location(1:5) ' ' ax.Legend.Location(6:end) ',' newline];
        axisstr = [axisstr 'legend pos=north east,' newline];
    end
    
    axisstr = [axisstr 'xmin=' num2str(ax.XLim(1)) ',' newline ...
        'xmax=' num2str(ax.XLim(2)) ',' newline ...
        'ymin=' num2str(ax.YLim(1)) ',' newline ...
        'ymax=' num2str(ax.YLim(2)) ',' newline ...
    ']' newline];
end

% returns "\definecolors"
function colorstr = getColorsinPlots(plts)
    colorstr = '';
    for i = 1:length(plts)
        if(~strcmp(plts(i).Color, 'none'))
            colorstr = [colorstr, '\definecolor{lineColor', num2str(i), '}{rgb}{', sprintf('%f,%f,%f', plts(i).Color(1), plts(i).Color(2), plts(i).Color(3)), '}' newline];
        end
        if(strcmp(plts(i).MarkerEdgeColor, 'auto'))
            colorstr = [colorstr, '\definecolor{markerEdgeColor', num2str(i), '}{rgb}{', sprintf('%f,%f,%f', plts(i).Color(1), plts(i).Color(2), plts(i).Color(3)), '}' newline];
        else
            if(~strcmp(plts(i).MarkerEdgeColor, 'none'))
                colorstr = [colorstr, '\definecolor{markerEdgeColor', num2str(i), '}{rgb}{', sprintf('%f,%f,%f', plts(i).MarkerEdgeColor(1), plts(i).MarkerEdgeColor(2), plts(i).MarkerEdgeColor(3)), '}' newline];
            end
        end
        if(~strcmp(plts(i).MarkerFaceColor, 'none'))
            colorstr = [colorstr, '\definecolor{markerFillColor', num2str(i), '}{rgb}{', sprintf('%f,%f,%f', plts(i).MarkerFaceColor(1), plts(i).MarkerFaceColor(2), plts(i).MarkerFaceColor(3)), '}' newline];
        end
    end
end

function linestr = interpretLine(plt, pltnum)
    linestr = '';

    if(strcmp(plt.LineStyle,'none'))
        linestr = 'only marks';    
        return
    end

    switch(plt.LineStyle)
        case '-'
            linestr = 'solid';
        case '--'
            linestr = 'dashed';
        case ':'
            linestr = 'dotted';
        case '-.'
            linestr = 'dashdotted';
    end
    
    linestr = [linestr, ',color=lineColor', num2str(pltnum)];
    linestr = [linestr, ',line width=', num2str(plt.LineWidth), 'bp'];
    
    if(strcmp(plt.Type, 'stair'))
        linestr = [linestr, ',const plot'];
    end
end

function markstr = interpretMarker(plt, pltnum)
    markoptstr = '';
    markstr = '';

    if(strcmp(plt.Marker,'none')) return; end

    switch(plt.Marker)
        case 'o'
            markstr = 'mark=o';
        case '+'
            markstr = 'mark=+';
        case '*'
            markstr = 'mark=asterisk';
        case 'x'
            markstr = 'mark=x';
        case '_'
            markstr = 'mark=-';
        case '|'
            markstr = 'mark=|';
        case 's'
            markstr = 'mark=square';
        case 'd'
            markstr = 'mark=diamond';
        case '^'
            markstr = 'mark=triangle';
        case 'v'
            markstr = 'mark=triangle';
            markoptstr = [markoptstr,'rotate=180,'];
        case '>'
            markstr = 'mark=triangle';
            markoptstr = [markoptstr,'rotate=270,'];
        case '<'
            markstr = 'mark=triangle';
            markoptstr = [markoptstr,'rotate=90,'];
        otherwise
            disp('Sorry, the mark '+ plt.Marker + ' is not compatible with TikZ. Type no mark.');
            markstr = '';
    end

    markstr = [markstr, ',mark size=',num2str(plt.MarkerSize),'bp'];
    
    if(~strcmp(plt.MarkerFaceColor, 'none'))
        markoptstr = [markoptstr,'fill=markerFillColor,', num2str(pltnum)];
    end
    if(~strcmp(plt.MarkerEdgeColor, 'none'))
        markoptstr = [markoptstr,'draw=markerEdgeColor,', num2str(pltnum)];
    end
    if(length(markoptstr) >= 1)
        markstr = [markstr, ',mark options={', markoptstr, '}'];
    end
end

function axistype = interpretaxistype(ax)
    if(strcmp(ax.XScale, 'log') && strcmp(ax.YScale, 'log'))
        axistype = 'loglogaxis';
    else
        if(strcmp(ax.XScale, 'log') && strcmp(ax.YScale, 'linear'))
            axistype = 'semilogxaxis';
        else
            if(strcmp(ax.XScale, 'linear') && strcmp(ax.YScale, 'log'))
                axistype = 'semilogyaxis';
            else
                axistype = 'axis';
            end
        end
    end
end

function legendstr = interpretlegend(leg)
    legendstr = '';
    
    if(isempty(leg)) return; end

    for i = 1:length(leg.String)
        if i > 1
            legendstr = [legendstr ',' leg.String{i}];
        else
        legendstr = [legendstr leg.String{i}];
        end
    end
    
end

function plots = findplotinaxis(ax)
    plots = [];
    for i = 1:length(ax.Children)
        if(strcmp(ax.Children(i).Type,'hggroup'))
            plots = [plots findplotinaxis(ax.Children(i))];
        else
            if(~(length(ax.Children(i).XData) == 1 && isnan(ax.Children(i).XData)))
                plots = [plots ax.Children(i)];
            end
        end
    end
end
