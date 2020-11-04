function PlotTrace(handles)

global ScaleBar Trace Flags

if Trace.Flag

    Ind = Trace.Subgroup.ID;
    T = Trace.Axis.Lim(2)-Trace.Axis.Lim(1);
%     SBxlim = ScaleBar.XFactor*T; % depends on the gui size of the axis allocated for the scalebar
%     SBx = floor(SBxlim);
%     SBxStr = sprintf('%d sec',SBx);
%     R = Trace.Axis.Lim(4);
%     SBylim = ScaleBar.YFactor*R;
%     SBy = floor(SBylim);
%     SByStr = sprintf('%g %%', SBy);
    
    Ind1 = Trace.Param.Switch+1;
    Ind2 = 2-Trace.Param.Switch;
    
    YMarks = ones(size(Trace.Subgroup.Marks))*Trace.Axis.Lim(3);
    
    axes(handles.axes_Motion)
%     plot(Trace.Data.T(Ind), Trace.ROI.C_M(Ind,1), 'r')
    plot(Trace.Data.T(Ind), Trace.ROI.C_M(Ind,2), 'r')
    hold on
    text(Trace.Data.T(Trace.Subgroup.Marks), zeros(size(Trace.Subgroup.Marks)), '\uparrow', 'HorizontalAlignment', 'Center', 'Color', [0 0 1], 'FontWeight', 'demi')
    axis off
    xlabel('Centroid Movement')
    set(handles.text_axes_Motion, 'String', 'Motion');
    hold off
    xlim(Trace.Axis.Lim(1:2))

    axes(handles.axes_Trace1)
    hold off
    plot(Trace.Data.T(Ind), Trace.Data.Fluo(1,Ind), Trace.Param.Color(Ind1),'LineWidth', 6)
    hold on
    plot(Trace.Data.T(Ind), Trace.Data.Fluo(1,Ind),'k')
%     hold on
%     plot(Trace.Data.T(Trace.Subgroup.Lost), Trace.Data.Fluo(1,Trace.Subgroup.Lost), 'r.')
    hold off
    axis off
    xlim(Trace.Axis.Lim(1:2))

    axes(handles.axes_Trace2)
    hold off
    plot(Trace.Data.T(Ind), Trace.Data.Fluo(2,Ind), Trace.Param.Color(Ind2),'LineWidth', 6)
    hold on
    plot(Trace.Data.T(Ind), Trace.Data.Fluo(2,Ind), 'k')
%     hold on
%     plot(Trace.Subgroup.Lost, Trace.Data.Fluo(2,Trace.Subgroup.Lost), 'r.')
    hold off
    axis off
    xlim(Trace.Axis.Lim(1:2))

    axes(handles.axes_Ratio)
    axis on
    hold off
    plot(Trace.Data.T(Ind), Trace.Analyzed.Ratio(Ind), 'k','LineWidth', 2)
    hold on
    text(Trace.Data.T(Trace.Subgroup.Marks), YMarks, '\uparrow', 'HorizontalAlignment', 'Center', 'Color', [0 0 1], 'FontWeight', 'demi')
%     plot(Trace.Data.T(Trace.Subgroup.Lost), Trace.Analyzed.Ratio(Trace.Subgroup.Lost), 'r.')
%     axis off
    set(handles.text_axes_Ratio, 'String', 'Ratio');
    hold off
    axis(Trace.Axis.Lim)

    switch Flags.Mode
        case {1, 3} % Split or Dual
            haxes = handles.axes_frame2;
        case 2 % Single
            haxes = handles.axes_single;
    end
    axes(haxes)
    plot(Trace.ROI.C_M(Ind,1) + Trace.ROI.Offset(1), Trace.ROI.C_M(Ind,2) + Trace.ROI.Offset(2), 'r')

%     axes(handles.axes_ScaleBar)
%     hold off
%     plot([SBxlim-SBx SBxlim], [0 0], 'Color', [0 0 0], 'LineWidth', 2);
%     hold on
%     plot([SBxlim-SBx SBxlim-SBx], [0 SBy], 'Color', [0 0 0], 'LineWidth', 1.5);
%     axis([0 SBxlim 0 SBylim]);
%     axis off
%     set(handles.axes_ScaleBar, 'Color', 'none', 'XTick', [], 'YTick', [])
%     dfx = 10/ScaleBar.Position(3)*T;
%     dfy = 10/ScaleBar.Position(4)*R;
%     text(SBxlim-SBx/2, -dfy/2, SBxStr, 'Color', [0 0 0], 'HorizontalAlignment', 'center')
%     text(SBxlim-SBx-dfx/5, SBy/2, SByStr, 'Color', [0 0 0],...
%         'HorizontalAlignment', 'center','Rotation', 90)
    
end

